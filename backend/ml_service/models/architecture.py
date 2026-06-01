import torch
import torch.nn as nn
import torch.nn.functional as F
import lightning as L
import config

class ResBlock(nn.Module):
    """Standard ResNet building block for spatial board representations."""
    def __init__(self, channels: int):
        super().__init__()
        self.conv1 = nn.Conv2d(channels, channels, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(channels)
        self.conv2 = nn.Conv2d(channels, channels, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm2d(channels)

    def forward(self, x):
        residual = x
        out = F.relu(self.bn1(self.conv1(x)))
        out = self.bn2(self.conv2(out))
        out += residual
        return F.relu(out)


class DankFishNet(nn.Module):
    """
    Core PyTorch network featuring convolutional ResNet blocks and multi-task heads:
    1. Policy Head: Predicts move probabilities [0..4095]
    2. Attention Head: Predicts human cognitive focus heatmap [0..63]
    """
    def __init__(self, in_channels: int = config.INPUT_CHANNELS):
        super().__init__()
        # Initial projection
        self.conv_init = nn.Conv2d(in_channels, 64, kernel_size=3, padding=1)
        self.bn_init = nn.BatchNorm2d(64)
        
        # Residual backbone to learn board geometry
        self.res1 = ResBlock(64)
        self.res2 = ResBlock(64)
        self.res3 = ResBlock(64)
        
        # 1. Policy Head (UCI move prediction)
        self.policy_conv = nn.Conv2d(64, 32, kernel_size=1)
        self.policy_bn = nn.BatchNorm2d(32)
        self.policy_fc = nn.Linear(32 * 8 * 8, config.POLICY_OUTPUT_SIZE)
        
        # 2. Attention Head (ADHD visual tunnel vision heatmap)
        self.attn_conv = nn.Conv2d(64, 16, kernel_size=1)
        self.attn_bn = nn.BatchNorm2d(16)
        self.attn_fc = nn.Linear(16 * 8 * 8, 64)

    def forward(self, x):
        # Backbone
        out = F.relu(self.bn_init(self.conv_init(x)))
        out = self.res1(out)
        out = self.res2(out)
        out = self.res3(out)
        
        # Policy prediction (logits)
        p = F.relu(self.policy_bn(self.policy_conv(out)))
        p = p.view(p.size(0), -1)
        policy_logits = self.policy_fc(p)
        
        # Attention heatmap prediction (probabilities via sigmoid)
        a = F.relu(self.attn_bn(self.attn_conv(out)))
        a = a.view(a.size(0), -1)
        attn_probs = torch.sigmoid(self.attn_fc(a))
        
        return policy_logits, attn_probs


class DankFishModel(L.LightningModule):
    """
    PyTorch Lightning Wrapper executing multi-task training and custom
    blunder-weighted loss calculations.
    """
    def __init__(self, learning_rate: float = config.LEARNING_RATE):
        super().__init__()
        self.save_hyperparameters()
        self.net = DankFishNet()
        self.learning_rate = learning_rate

    def forward(self, x):
        return self.net(x)

    def training_step(self, batch, batch_idx):
        tensors, move_targets, attention_targets, is_blunder = batch
        
        # Run forward pass
        policy_logits, attn_probs = self(tensors)
        
        # 1. Policy Loss (with blunder-weighted multipliers)
        # Compute standard cross-entropy per sample (reduction='none' to scale individually)
        raw_policy_loss = F.cross_entropy(policy_logits, move_targets, reduction='none')
        # Scale loss: blunders are weighted 3x (1.0 + 2.0) to focus learning on mistakes
        loss_weights = 1.0 + (is_blunder * 2.0)
        policy_loss = torch.mean(raw_policy_loss * loss_weights)
        
        # 2. Attention Head Loss (Binary Cross-Entropy)
        attn_loss = F.binary_cross_entropy(attn_probs, attention_targets)
        
        # Combine multi-task losses
        total_loss = policy_loss + 0.5 * attn_loss
        
        # Log metrics
        self.log("train_loss", total_loss, on_step=True, on_epoch=True, prog_bar=True)
        self.log("train_policy_loss", policy_loss, on_epoch=True)
        self.log("train_attn_loss", attn_loss, on_epoch=True)
        
        return total_loss

    def validation_step(self, batch, batch_idx):
        tensors, move_targets, attention_targets, is_blunder = batch
        policy_logits, attn_probs = self(tensors)
        
        raw_policy_loss = F.cross_entropy(policy_logits, move_targets, reduction='none')
        loss_weights = 1.0 + (is_blunder * 2.0)
        policy_loss = torch.mean(raw_policy_loss * loss_weights)
        attn_loss = F.binary_cross_entropy(attn_probs, attention_targets)
        
        val_loss = policy_loss + 0.5 * attn_loss
        
        self.log("val_loss", val_loss, on_epoch=True, prog_bar=True)
        return val_loss

    def configure_optimizers(self):
        optimizer = torch.optim.AdamW(self.parameters(), lr=self.learning_rate, weight_decay=1e-4)
        return optimizer
