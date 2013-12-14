cd "`dirname "$0"`"/../../Game/Scripts
../../Love/osx/love.app/Contents/MacOS/love --console server
../../Love/osx/love.app/Contents/MacOS/love --console client user=`logname` ip=127.0.0.1