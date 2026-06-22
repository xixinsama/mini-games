# DestroyerRush
 STG, Boss Rush

# 关卡设计

## level 0
 奖励关，很多很多弹幕，不需要动就可以通关
## level 1
 双BOSS，左右各一边，攻击方式不同。
## level 2
 很多攻击模式
## level 3
 player变得极小（原本尺寸）
## level 4
 奖励关，手速小游戏
 动态难度具体为：

	if 70 > progress and progress > 50:
		enemy_count = randi_range(1, 4)
	elif  90 > progress and progress >= 70:
		enemy_count = randi_range(2, 4)
	elif  100 > progress and progress >= 90:
		enemy_count = randi_range(2, 3)
	elif  50 >= progress and progress >= 0:
		enemy_count = randi_range(0, 6)

## level 5
 BOSS关，前面的弹幕的大杂烩
