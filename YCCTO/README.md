# YCCTO

《You can come this ONE》《唯“一”可达》游戏源码库，一个走迷宫类游戏

1280*720

32*32

80*45

从左上角走到右下角

# 规则

所有格子下都有一个数字0,1,2,3

数字0的格子是墙

只有数字为1的格子可以走

数字2的格子是怪兽，走进该格子将额外减少倒计时2秒

数字3的格子是传送门，可传送到对应的数字3的格子

所有的格子都显示为周围四格的数字总和（上下左右四格），不包括自身

倒计时：当玩家进入游戏即开始倒计时，倒计时结束未到终点游戏失败，计时内达到则胜利

上下左右移动ui_left等

# 素材引用

tilemap:
自己画的

角色
https://gibbongl.itch.io/8-directional-gameboy-character-template

字体：
https://timothyqiu.itch.io/vonwaon-bitmap
