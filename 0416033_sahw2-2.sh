#!/bin/sh
if test -e timetable.json
then
    echo "Course exist"
else
    curl 'http://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crsname=**&m_cos_id=**&m_cos_code=**&m_crstie=**&m_crsoutline=**&m_costype=**' > timetable.json
fi

awk -F'"' '
BEGIN {
    name=0;
    time=0;
    count=0
}
{
    for(i=1;i<NF;i++){
        if($i ~ /cos_time/)
            time=(i+2);
        else if($i ~ /cos_ename/)
        {
            name=(i+2);
            count+=1;
            print count "," $name "," $time;
        }
    }
}
' timetable.json | sed -e 's/ /./g' -e 's/,/ /g'> classdata.txt
if test -e classselect.txt
then
    #back
else
    awk 'BEGIN{ORS="\n"}{printf("%s %s",$1,$2);for(i=3;i<=NF;i++)printf("-%s",$i);printf(" off \n")}' classdata.txt > classselect.txt
fi
if test -e timeformat.txt
then
    #do nothing
else
    awk 'BEGIN{
    arr[1]="M";
    arr[2]="N";
    arr[3]="A";
    arr[4]="B";
    arr[5]="C";
    arr[6]="D";
    arr[7]="X";
    arr[8]="E";
    arr[9]="F";
    arr[10]="G";
    arr[11]="H";
    arr[12]="Y";
    arr[13]="I";
    arr[14]="J";
    arr[15]="K";
    for(i=1;i<=15;i++)
    {
        for(j=1;j<=7;j++)
        {
            printf("%d%s,x.           ,.            ,.            ,.            \n",j,arr[i]);
        }
    }
}' > timeformat.txt
fi
if test -e option.txt
then
    #back
else

fi
dirty=1
state=1
local=0
extra=0
while :
do
    case $state in
        0) #options
            cp -f config.txt conf.tmp
            dialog --menu "option" 100 100 20 \
                1 "Show/Hide Classroom" \
                2 "Show/Hide Extra Column" \
                3 "Search Classes by Name" \
                4 "Search Classes by Time" 2>o.tmp
            op2=$?
            op=$(cat o.tmp)
            if [ "$op2" = "0" ]
            then
                case $op in
                    1)
                        awk '{if($1=="0")print "1",$2;else print"0",$2;}' conf.tmp > config.txt
                        state=2
                        ;;
                    2)
                        awk '{if($2=="0")print $1,"1";else print $1,"0";}' conf.tmp > config.txt
                        state=2
                        ;;
                    3)
                        state=3
                        ;;
                    4)
                        state=4
                        ;;
                    *)
                        ;;
                esac
                else
                    state=2
            fi
            rm -f conf.tmp
            rm -f o.tmp
            ;;
        1) #choose class
            if [ "$dirty" = "1" ]
            then
                cp -f classselect.txt c.tmp
                dirty=0
            fi
            dialog --buildlist "Select your course" 100 100 20 \
                $(cat c.tmp) 2>out.txt
            if [ "$?" = "0" ]
                then
                sed -i.bak 's/ on / off /g' c.tmp
                for index in $(cat out.txt)
                do
                    sed -i.bak "${index}s/ off / on /" c.tmp
                done
                awk -F '[ -]' '/ on /{for(i=2;i<=(NF-3);i+=2)print $(i+1),$2 "-" $(i+2);}' c.tmp | awk 'BEGIN{OFS="";digit=0;char="a"}{
                    split($1, thing, "")
                    for(i=1;i<=length($1);i++){
                        if(thing[i]~/[0-9]/)
                        {
                            digit=thing[i];
                        }
                        else
                        {
                            char=thing[i];
                            printf("%d%s %s\n",digit,char,$2);
                        }
                    }
                }' > tempclass.txt
            collilog="$(sort -k 1 tempclass.txt | rev | uniq -d -f 1 | rev)"
                if [ "$collilog" = "" ]
                then
                    awk -F'[ -,]' 'BEGIN{count=0;hit=0;}
                    {}
                    NR==FNR{
                    time[FNR]=$1;
                    name[FNR]=$2;
                    loca[FNR]=$3;
                    count++;
                }
            NR!=FNR{
                for(i=1;i<=count;i++)
                {
                   if($1 == time[i])
                        hit=i;
                }
                if(hit!=0){
                    printf("%s,",$1);
                    split(name[hit],temp,"")
                    for(j=1;j<=39;j++)
                    {
                        if(j<length(temp))
                            {printf("%s"),temp[j];}
                        else if(j%13==1)
                            {printf(".");}
                        else
                            {printf(" ");}
                        if(j%13==0)
                            {printf(",");}
                    }
                    printf("%-13s\n",loca[hit]);
                }
                else{print $0;}
                hit=0;
            }' tempclass.txt timeformat.txt > tabletime.txt
                cp -f c.tmp classselect.txt
                else
                    dialog --msgbox "collision happens at:
$collilog" 50 50
                continue
                fi
            fi
            state=2
            rm -f c.tmp
            dirty=1
            ;;
        2) #show class
            if test -e config.txt
            then
                #do nothing
            else
                awk 'BEGIN{print "0 0"}' > config.txt
            fi
            conf=$(cat config.txt)
            if test "$conf" = "1 1"
            then
                local=1
                extra=1
            elif test "$conf" = "1 0"
            then
                local=1
                extra=0
            elif test "$conf" = "0 1"
            then
                local=0
                extra=1
            else
                local=0
                extra=0
            fi
                        #proccess the real table
    awk -F',' -v loc=$local -v ext=$extra 'BEGIN{
    OFS="  ";
    sep="==============";
    count=0;
    if(ext==0)
        print "x  .Mon            .Tue            .Wed            .Thu            .Fri            .Sat            .Sun";
    else
        print "x  .Mon            .Tue            .Wed            .Thu            .Fri";
    }
    {
        for(i=2;i<=5;i++)
            {count++;item[count]=$i;if(loc==0&&i==5)item[count]=".            ";}
    }
    NR%7==0{
        split($1,time,"");
        count=0;
        if(ext==1&&(time[2]~/[MNXY]/))
            next;
        for(j=1;j<=4;j++)
        {
            if(j!=1)
                printf(".  |");
            else
                printf("%s  |",time[2]);
                for(k=0;k<(7-ext*2);k++)
            {
                printf("%s  |",item[k*4+j])
            }
            printf("\n");
        }
        if(ext==0)
            print "=",sep,sep,sep,sep,sep,sep,sep,"=";
        else
            print "=",sep,sep,sep,sep,sep,"=";
    }' tabletime.txt > result.txt
    dialog --extra-button \
        --extra-label "Option" \
        --help-button \
        --help-label "EXIT"\
        --textbox result.txt 300 100
        op="$?"
            if [ "$op" = "3" ]
            then
                state=0
            elif [ "$op" = "0" ]
            then
                state=1
            else
                state=5
            fi
            ;;
        3)
            dialog --inputbox "Search by name:" 100 100 2>search.txt
            find="$(grep -i "$(cat search.txt)" classdata.txt)"
            dialog --msgbox "$find" 100 100
            state=2
            ;;
        4)
            dialog --inputbox "Search by time:" 100 100 2>search.txt
            find="$(grep -i "$(cat search.txt)" classdata.txt)"
            dialog --msgbox "$find" 100 100
            state=2
            ;;
        *)
            break
            ;;
    esac
done
