TableCreation це DDL файл для створення таблиць

OptimizationQuerys це самі query

main.py і requirements.txt файли для генерації даних для таблиць

*EA це файли з виводом explain analyze


Аналіз explain analyze:

Для неоптимізованої query ми отримали час порядку 200 ms та seq scan всюди
Далі в більш оптимізованій query без використання індексів ми зменшили час до 50ms що логічно бо замість 4 підзапитів ми рахуємо 1 CTE.
Після цього коли ми подивились на query2 з використанням індексів ми отримали час порядку 10ms, а коли відключити індекси виходить час порядку 15 ms, через що ми скоротили час на третину
<img width="1246" height="892" alt="image" src="https://github.com/user-attachments/assets/a2e201da-2d1a-4ccf-8d82-a9121069935c" />
