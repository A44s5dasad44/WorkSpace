cd C:\Users\HKX\Desktop\MyPaper_02
git init
git branch -M main
@REM 没链接远程，使用下述语句链接
@REM git remote add origin https://github.com/A44s5dasad44/MyPaper_02.git
@REM 若报出连接存在，则使用如下语句删除
@REM git remote rm origin
@echo on
@REM 获取三个命令行参数，第一个参数为本次提交的注释信息，第二个参数为本地分支名,第三个参数为要提交的远程分支名
@REM set comment=%1 
@REM set origin=%2
@REM set remote=%3
@REM echo current is:%date%
@REM echo current is:%TIME%
@REM Enter the commit information:
@REM set /p declation=
git add .
git commit -m "%date% %TIME%"
git push -u origin main







