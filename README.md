# otus_7_lesson_working_with_processes
Управление процессами

Написать свою реализацию ps ax используя анализ /proc
Результат ДЗ - рабочий скрипт который можно запустить

## /proc
Псевдофайловая система /proc является специальным механизмом, который позволяет получать информацию о системе от самого ядра. А значит аналог для ps ax выполне реализуем средствами bash.
Важные скрипты из курса:
```
ps -A #Все активные процессы
ps -A -u username #Все активные процессы конекретного пользователя
ps -eF #Полный формат вывода
ps -U root -u root #Все процессы работающие от рута
ps -fG group_name #Все процессы запущенные от группы
ps -fp PID #процессы по PID (можно указать пачкой)
ps -e --forest #Показать древо процессов
ps -fL -C httpd #Вывести все треды конкретного процесса
ps -eo pid,tt,user,fname,tmout,f,wchan #Форматируем вывод
ps -C httpd #Показываем родителы и дочерние процессы
ps -eLf # информация о тредах
ps axo rss | tail -n +2|paste -sd+ | bc
```
## ps ax
Что выводит ps ax:
PID - Идентификатор процесса
TTY - терминал, с которым связан данный процесс. Идентификатор управляющего терминала
STAT - Текущий статус процесса:
      R — выполняется
      D — ожидает записи на диск
      S — неактивен (< 20 с)
      T — приостановлен
      Z — зомби
          Дополнительные флаги:
            W — процесс выгружен на диск
            < — процесс имеет повышенный приоритет
            N — процесс имеет пониженный приоритет
            L — некоторые страницы блокированы в оперативной памяти
            s — процесс является лидером сеанса
TIME - Количество времени центрального процессора, затраченное на выполнение процесса
COMMAND - Имя и аргументы команды

## Вытягиваем по частям из /prcoc
Для начала выполним вычисления под конкретный процесс, затем соберем всё необходимое в полноценный bash скрипт с функциями и переменными

### Получаем PID процесса
```
cat /proc/9/status | grep Pid | awk '(NR == 1)' | cut -f2 -d ":" | cut -f2
```
P.S. Для того, чтобы узнать PID текущего процесса, можно использовать специальную переменную окружения $$
+ Полезные штуки для bash http://ruvds.com/doc/bash.pdf

### Получаем состояние процесса:
```
cat /proc/9/status | awk '(NR == 3)' | cut -f2 -d ":" | cut -f2 | sed "s/9/"Z"/g"
```
Т.к. состояние зомби процесса обозначается также как и его PID то для красоты (с помощью sed) заменим на букву Z. Чтобы симитировать такой процесс был написал и вызван простой скрипт:
```
sleep 1 & exec /bin/sleep 1000
```

### Получаем время выполнения процесса:
Для начала поймем откуда вытаскивать время запуска процесса. Статья в помощь:
https://www.baeldung.com/linux/total-process-cpu-usage

В специальном файле /proc/<pid>/stat есть два значения с использованием ЦП процессом. Одно значение называется utime , а другое — stime , это 14-е и 15-е значения соответственно.Значение utime — это время, в течение которого процесс выполнялся в пользовательском режиме. Значение stime — это количество времени, в течение которого процесс выполнялся в режиме ядра. Общее использование ЦП приложением равно сумме utime и stime , деленной на прошедшее время.
Рассчитаем все это в скрипте:
```
PROCESS_STAT=$(sed -E 's/\([^)]+\)/X/' "/proc/$pid/stat")
PROCESS_UTIME=$(cat /proc/$pid/stat | awk '{print $13}')
PROCESS_STIME=$(cat /proc/$pid/stat | awk '{print $14}')
PROCESS_STARTTIME=$(cat /proc/$pid/stat | awk '{print $21}')
SYSTEM_UPTIME_SEC=$(tr . ' ' </proc/uptime | awk '{print $1}')
CLK_TCK=$(getconf CLK_TCK)
        let PROCESS_UTIME_SEC="$PROCESS_UTIME / $CLK_TCK"
        let PROCESS_STIME_SEC="$PROCESS_STIME / $CLK_TCK"
        let PROCESS_USAGE_SEC="$PROCESS_UTIME_SEC + $PROCESS_STIME_SEC"
      
echo "${PROCESS_USAGE_SEC}s"
```
P.S. (пока игрался с датой/временем). Есть набор утилит от dateutils чтобы через ddiff посчитать разницу между датами. Текущую дату получать можно так:
```
date +"%Y-%m-%d %H:%M:%S"
```
      
### Получаем имя процесса:
```
cat /proc/8580/status | awk '(NR == 1)' | cut -f2 -d ":" | cut -f2   
```

## Собираем в один скрипт:
```
#!/bin/bash
echo "info from proc"
echo PID $'\t' STATE $'\t'$'\t' TIME $'\t' COMMAND
echo --------  ------------  $'\t' ---  $'\t' ------------
for valpid in /proc/[0-9]*
do

pid=$(cat $valpid/status | grep Pid | awk '(NR == 1)' | cut -f2 -d ":" | cut -f2)

stat=$(cat $valpid/status | awk '(NR == 3)' | cut -f2 -d ":" | cut -f2 | sed "s/${pid}/"Z"/g")

PROCESS_STAT=$(sed -E 's/\([^)]+\)/X/' "/proc/$pid/stat")
PROCESS_UTIME=$(cat /proc/$pid/stat | awk '{print $13}')
PROCESS_STIME=$(cat /proc/$pid/stat | awk '{print $14}')
PROCESS_STARTTIME=$(cat /proc/$pid/stat | awk '{print $21}')
SYSTEM_UPTIME_SEC=$(tr . ' ' </proc/uptime | awk '{print $1}')
CLK_TCK=$(getconf CLK_TCK)
        let PROCESS_UTIME_SEC="$PROCESS_UTIME / $CLK_TCK"
        let PROCESS_STIME_SEC="$PROCESS_STIME / $CLK_TCK"
        let PROCESS_USAGE_SEC="$PROCESS_UTIME_SEC + $PROCESS_STIME_SEC"

name=$(cat $valpid/status | awk '(NR == 1)' | cut -f2 -d ":" | cut -f2)

echo "${pid}" $'\t' "${stat}" $'\t' "${PROCESS_USAGE_SEC}s" $'\t' "${name}"
done
```
      
