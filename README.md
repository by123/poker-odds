# Poker Odds Calculator ♠️

德州扑克胜率计算器 - iOS App

## 功能

- 🃏 设置你的两张手牌
- 🎴 设置公共牌 (0/3/4/5 张)
- 👥 选择对手数量 (1-9人)
- 📊 蒙特卡洛模拟计算胜率

## 技术栈

- Swift 5.9
- SwiftUI
- iOS 17+
- XcodeGen

## 构建

```bash
# 安装 XcodeGen (如果没有)
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate

# 打开项目
open PokerOdds.xcodeproj
```

## 算法

使用蒙特卡洛模拟 (默认 20,000 次) 计算胜率：

1. 根据已知牌面，随机发剩余的公共牌
2. 给每个对手随机发两张手牌
3. 评估所有玩家的最佳 5 张牌组合
4. 统计胜/平/负次数

## 牌型 (从低到高)

1. 高牌 (High Card)
2. 一对 (One Pair)
3. 两对 (Two Pair)
4. 三条 (Three of a Kind)
5. 顺子 (Straight)
6. 同花 (Flush)
7. 葫芦 (Full House)
8. 四条 (Four of a Kind)
9. 同花顺 (Straight Flush)
10. 皇家同花顺 (Royal Flush)

## License

MIT
