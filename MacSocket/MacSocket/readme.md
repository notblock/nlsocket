通过套字节发送和接收
1、监听ip：0.0.0.0， 监听端口可以配置
2、接收协议：
from:<ip_address>
to:<发送给[聊天室or单个client]>
token:<验证信息，必要字段，若为空则直接断开连接>
date:<时间戳>
length:<发送长度>
data:<发送数据>
type:<类型>
3、储存到本地
