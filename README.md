# JNPlayer
avplayer添加本地缓存

由于项目需要，展示一个类似微博在tableview中边下边播，并且有本地缓存的视频播放器，网上也搜不到符合需求的轻量级视频播放器，所以自己用avplayer实现了一个，
具体UI部分不再赘述可以参照代码，只说一下实现边下边播以及缓存的大致实现的思路

![image]
(https://github.com/jiananMars/JNPlayer/blob/master/2018-11-19%2017_46_07.gif)

边下边播：
通过KVO监听item的playbackBufferEmpty，playbackLikelyToKeepUp，通过不同状态来暂停或者播放

缓存：
通过KVO监听loadedTimeRanges，比较总长度以及加载长度，如果视频加载完成，创建音视频轨道并进行压缩保存

ps：由于本地保存成功后视频有方向问题，所以根据preferredTransform判断修正方向后再保存
