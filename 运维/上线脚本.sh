#!/bin/bash
export JAVA_HOME=/usr/local/jdk1.7.0_67
export JRE_HOME=${JAVA_HOME}/jre 
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
 
dir_path="/apps/project/project_name"
work="project_name"
DATE=`date +%Y%m%d%H%M`
tomcat="apache-tomcat-6.0.41_project_name"
 
cd $dir_path
if [ ! -d wars ];then
    mkdir wars
fi
 
if [ -d ROOT ];then
    tar cfz ROOT-$DATE.tar.gz ROOT
    mv ROOT-$DATE.tar.gz wars/
fi
 
git_update(){
    tag_version=$1
    cd $dir_path/$work
    git checkout master
    git pull
    echo $tag_version
    git_tag=`git tag|grep -x $tag_version`
    if [ "$git_tag" = "$tag_version" ];then
        git checkout -b `date +%Y%m%d%H%M` $git_tag
    else
        printf "tag number input error \n"
        exit 1
    fi
    git_id1=`git log -1 --format=%H`
    git_id2=`git show $git_tag |grep commit |awk '{print $2}' |head -1`
    if [ "$git_id1" != "$git_id2" ];then
        printf "The current git branch where inconsistent tag number is correct , please check the tag number \n"
        exit 1
    fi
}
 
tag_version=$1
 
if [ "$tag_version" = "" ];then
    printf "Please enter the version number \n"
    exit 1
else
    git_update $1
    echo $1 >> ${dir_path}/tag.txt
fi
 
build(){
    dir_path=$1
    work=$2
    cd $dir_path/$work
    mvn package -DskipTests
    if [ -d $dir_path/$work/target ];then
        cd $dir_path/$work/target
    else
        echo "build $dir_path/$work failed"
        exit
    fi
    return 1
}
 
build $dir_path $work
type=$?
if [ $type -eq 1 ];then
    cd $dir_path/$work/target
    work_name=`ls  |grep $work |grep -v "war\|jar\|gz"`
else
    echo "build failure"
    exit 1
fi
 
if [ -d $dir_path/ROOT ];then
    rm -rf $dir_path/ROOT
fi
 
cd $dir_path/$work/target/
mv  $work_name $dir_path/ROOT
 
if [ -d $dir_path/ROOT ];then
    scp $dir_path/config.properties  $dir_path/ROOT/WEB-INF/classes/
    scp $dir_path/redis.properties  $dir_path/ROOT/WEB-INF/classes/
    scp $dir_path/jdbc.properties  $dir_path/ROOT/WEB-INF/classes/
fi
 
tomcat_status=`ps aux |grep $tomcat |grep -v "gerp">/dev/null;echo $?`
 
if [ $tomcat_status -eq 0 ];then
    kill -9 `ps aux |grep $tomcat |grep -v "grep"|awk '{print $2}'`;rm -rf /usr/local/$tomcat/work/*;rm -rf /usr/local/$tomcat/temp/*;/usr/local/$tomcat/bin/startup.sh
else
    rm -rf /usr/local/$tomcat/work/*;rm -rf /usr/local/$tomcat/temp/*;/usr/local/$tomcat/bin/startup.sh
fi
