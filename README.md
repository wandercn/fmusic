# fmusic
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/wandercn/fmusic?color=peru)](https://github.com/wandercn/fmusic/releases/latest)
[![Lines of code](https://img.shields.io/tokei/lines/github/wandercn/fmusic.svg?color=beige)](#)
[![Downloads of releases](https://img.shields.io/github/downloads/wandercn/fmusic/total.svg?color=lavender)](https://github.com/wandercn/fmusic/releases/latest)
[![GPL3 licensed](https://img.shields.io/github/license/wandercn/fmusic.svg)](./LICENSE)


 <img src="logo/logo.png" width = "100" height = "100" alt="fmusic" align=center />
 

基于SwiftUI开发的本地音乐播放器,系统最低要求macos 11.0,开发环境Xcode Version 13.4.1 
1. [x] 能自动解析音频文件的，专辑信息和专辑封面图片
2. [x] 经过测试支持 [".flac", ".mp3", ".wav", ".m4a", ".aif", ".m4r"]音乐文件的播放
3. [x] 歌曲列表单行双击，切歌。
4. [x] 播放模式支持 顺序，循环，随机，单曲循环。
5. [x] 导入音乐文件夹，支持图标点击，菜单，快捷键方式（commd + o）三种方式
6. [x] 播放进度条，支持鼠标拖拽调整。
7. [x] 简单的收藏功能。
8. [x] 搜索，模糊匹配 歌曲名/艺术家/专辑
9. [x] 左边栏支持隐藏
10. [x] 音乐音量调整
11. [ ] 播放列表暂时没有实现,后续有时间再开发（有能力的可以帮忙开发）
12. [ ] 向下兼容开发支持mac10.15系统，目前在m1mac笔记本12.0系统上选择编译目标target 10.15能编译运行，但是在intel10.15真机上运行不了。兼容mac10.15单独 开个仓库 https://github.com/wandercn/myPlayer 有mac10.15系统的朋友可以帮忙试试能不能编译成功。

13. [x] 增加清空资料库功能，支持菜单和图标按钮两种方式。

14. [x] 资料库歌曲排序，按专辑名和音轨序号track排序，保持跟原始专辑歌曲顺序一致。
15. [x] 歌曲列表，增加了右键菜单-编辑元信息。修改歌曲的名称，专辑，艺术家保存在音频文件里。目前兼容比较好的是 flac，mp3 ，m4a(v1.0.3)
16. [x] 歌曲列表，增加了右键菜单-编辑元信息，增加字段音轨序号 track。元信息修改，同步修改列表的信息。（v1.0.4)
17. [x] 歌曲列表，增加了右键菜单-文件详情，可以查看文件详细，文件路径。快速重命名文件的功能。(v1.0.4)
18. [x] 增加了歌词显示，自动下载歌词功能. 歌词文件存储在～/Music/Lyrics目录中（v1.07)

# FAQ

1. macOS系统限制，提示”提示文件已损坏” 或者 “无法打开“fmusic”，因为Apple无法检查其是否包含恶意软件"，处理方法。

sudo xattr -d com.apple.quarantine /Applications/xxxx.app，注意：/Applications/xxxx.app 换成你的App路径。指定放行，删除com.apple.quarantine元数据文件，使您可以执行可执行文件。

# Screen

![](logo/player.jpg)
