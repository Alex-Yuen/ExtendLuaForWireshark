set DstPath=D:\Program Files\Wireshark\LuaPlugins

::mklink /H /J "%DstPath%\TXSSO2"  .\TXSSO2

rd "%DstPath\TXSSO2.luax"

copy .\TXSSO2.lua "%DstPath%\TXSSO2.luax"


::ʹ�÷���
::����Ӧ��lua52.dll����WiresharkĿ¼�µ�lua52.dll��
::��WiresharkĿ¼���½�Ŀ¼LuaPlugins
::��TXSSO2.lua��TXSSO2�ļ���Copy��LuaPluginsĿ¼
::��TXSSO2.lua��׺��Ϊluae��
::have fun