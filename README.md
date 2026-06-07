# Dashboard_Video_Game_Sales
Source: https://figshare.com/articles/dataset/Video_game_sales/31939302
Accessed at: 15-May-2026

Extract
1. Using OPENROWSET() to get data from source
2. Due to limitation import of SQL, the "NaN" is replaced with "null" through notepad
3. Insert data into #temptable

Transform
1. Handling duplicate data with filtered on game name and platform that have more than one data
2. Delete records containing at least a null value (occurred in Released Year and Publisher)

Load
1. Insert final #temptable into permanent table
2. Adding new data from other source to give detail explanation about platform


Conclusion and action
1. In general, for all type consoles
- Top Game: Wii Sports, GTA V, Super Mario Bross
- Top Publishers: Electronic Arts, Activision, Ubi Soft
- Top Genre: Action, Sports, Shooter

--> Recommendation: Focus on Action and Sports games to increase sales due to different top game and publisher. For action genre, the recommended publisher is Electronic Arts. On the other hand, for Sport Genre, the recommended game is Wii Sports.

2. For Home Consoles
- Same like all consoles. Home consoles is dominating for all sales.

3. For Handheld
- Top Game: Pokemon Red/Pokemon Blue, Tetris, New Super Mario Bross
- Top Publishers: Nintendo, THQ, Ubisoft
- Top Genre: Role-Playing, Action, Platform

--> Recommendation: Focus on Role-Playing game to increase sales with game like Pokemon Red/Pokemon Blue. The recommendation is only one due to the is produced by Nintendo as top publishers

4. For PC Gaming
- Top Game: The Sims 3, World of Warcraft, Diablo III
- Top Publishers: Electronic Arts, Activision, Ubisoft
- Top Genre: Simulation, Role-Playing, Strategy

--> Recommendation: Focus on Simulation and Role Playing games to increase sales due to different top game and publisher. The recommendation games are The Sims 3 (published by Electronic Arts) and World of Warcraft (published by Activision).

