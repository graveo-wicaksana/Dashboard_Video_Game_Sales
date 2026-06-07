--1. Load json file. Using version 2 due to the replacing of "Year": NaN with "Year": null through notepad and maintain the original data
DECLARE @json NVARCHAR(max);

SELECT @json = BulkColumn
FROM OPENROWSET (
	BULK 'C:\File_Graveo\2026_Dataset\Power_BI_Part_3_Video_Games_Sales\31939302\vgsales_2.json',
	SINGLE_CLOB
) AS j;

--Preview the file
SELECT * FROM OPENJSON(@json)
--total 16598 records with Rank 654, and Rank 14200 are missing from raw data


--2. Make temporary table 
DROP TABLE IF EXISTS #VideoGamesSales
CREATE TABLE #VideoGamesSales
(
	RankID INT, GameName VARCHAR(100), Platform_ VARCHAR(20), 
	ReleaseYear FLOAT, Genre	VARCHAR(20), Publisher VARCHAR(50), 
	NorthAmerican_Sales FLOAT, EuropeanUnion_Sales FLOAT, Japan_Sales FLOAT, 
	Other_Sales FLOAT, Global_Sales FLOAT
)


--3. Insert temporary table using data from json file
INSERT INTO #VideoGamesSales
SELECT
	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RankID, 
	GameName, Platform_, ReleaseYear, Genre, Publisher, 
	NorthAmerican_Sales, EuropeanUnion_Sales, Japan_Sales, Other_Sales, Global_Sales
FROM
	OPENJSON(@json)
WITH
	(
	RankID INT '$.Rank', GameName VARCHAR(100) '$.Name', Platform_ VARCHAR(20) '$.Platform', 
	ReleaseYear FLOAT '$.Year', Genre	VARCHAR(20) '$.Genre', Publisher VARCHAR(50) '$.Publisher', 
	NorthAmerican_Sales FLOAT '$.NA_Sales', EuropeanUnion_Sales FLOAT '$.EU_Sales', Japan_Sales FLOAT '$.JP_Sales', 
	Other_Sales FLOAT '$.Other_Sales', Global_Sales FLOAT '$.Global_Sales'
)

--script from 1 to 3 must be executed together due to json file will be closed as the script is executed


--4. Cleaning data
--A. Handling duplicate data

--Check gamename, platform more than one data
SELECT GameName, Platform_, COUNT(*) total from #VideoGamesSales
GROUP BY GameName, Platform_
HAVING COUNT (*) > 1

--Wii de Asobu: Metroid Prime
SELECT * FROM #VideoGamesSales
WHERE GameName = 'Wii de Asobu: Metroid Prime'
--Deleting the last record of Wii de Asobu: Metroid Prime due to duplicate data with only different rankID
DELETE FROM #VideoGamesSales 
WHERE RankID = '15000'

--Sonic the Hedgehog
SELECT * FROM #VideoGamesSales
WHERE GameName = 'Sonic the Hedgehog'
--Deleting the record of Sonic the Hedgehog with Release Year and Publisher are NULL. It is indicated not completed data from the beginning
DELETE FROM #VideoGamesSales 
WHERE GameName = 'Sonic the Hedgehog'
	AND Platform_ = 'PS3'
	AND ReleaseYear IS NULL
	AND Publisher IS NULL

--Madden NFL 13
SELECT * FROM #VideoGamesSales
WHERE GameName = 'Madden NFL 13'
--Merge data for platform PS3 since the data just differ for sales data and rank ID. the rest is same
UPDATE A
SET A.NorthAmerican_Sales = A.NorthAmerican_Sales + B.NorthAmerican_Sales,
	A.EuropeanUnion_Sales = A.EuropeanUnion_Sales + B.EuropeanUnion_Sales,
	A.Japan_Sales = A.Japan_Sales + B.Japan_Sales,
	A.Other_Sales = A.Other_Sales + B.Other_Sales,
	A.Global_Sales = A.Global_Sales + B.Global_Sales
FROM #VideoGamesSales A
JOIN #VideoGamesSales B
	ON A.GameName = B.GameName
	AND A.Platform_ = B.Platform_
	AND A.ReleaseYear = B.ReleaseYear
WHERE
	A.RankID = 604
	AND B.RankID = 16128
--DELETE LAST RECORD
DELETE FROM #VideoGamesSales
WHERE RankID = '16128'

--Need for Speed: Most Wanted
SELECT * FROM #VideoGamesSales
WHERE GameName = 'Need for Speed: Most Wanted'
AND Platform_ in ('PC', 'X360')
--Different release year and different version based on real game. No deleted


--B. Handling null values
--Check null values
SELECT * FROM #VideoGamesSales
WHERE 
	RankID IS NULL OR
	GameName IS NULL OR 
	Platform_ IS NULL OR
	ReleaseYear IS NULL OR
	Genre IS NULL OR
	Publisher IS NULL OR
	NorthAmerican_Sales	IS NULL OR
	EuropeanUnion_Sales	IS NULL OR
	Japan_Sales	IS NULL OR
	Other_Sales	IS NULL OR
	Global_Sales IS NULL
--NULL appears in ReleaseYear and Publisher. It's suspected that the data is not filled completely

--Compare Percentage of null values to all the data.
SELECT 
	CONVERT (FLOAT, (SELECT 
							COUNT(*) AS qty_contain_NULL FROM #VideoGamesSales
					 WHERE 
							RankID IS NULL OR
							GameName IS NULL OR 
							Platform_ IS NULL OR
							ReleaseYear IS NULL OR
							Genre IS NULL OR
							Publisher IS NULL OR
							NorthAmerican_Sales	IS NULL OR
							EuropeanUnion_Sales	IS NULL OR
							Japan_Sales	IS NULL OR
							Other_Sales	IS NULL OR
							Global_Sales IS NULL)
			)
/(SELECT COUNT(*) AS qty_all FROM #VideoGamesSales) * 100 AS percentage_null_based_quantity
--Percentage Null data to all data is 1.8%.  

--Check impact to sales data
SELECT *, 
	ROUND(vgs_all.total_sales_all - vgs_no_null.total_sales_no_Null, 2) difference_, 
	ROUND(((vgs_all.total_sales_all - vgs_no_null.total_sales_no_Null)/vgs_all.total_sales_all)*100, 2) percentage_dif_to_total_sales_all FROM
(SELECT ROUND(SUM(Global_Sales), 2) AS total_sales_all FROM #VideoGamesSales) vgs_all
CROSS JOIN
(SELECT ROUND(SUM(Global_Sales), 2) AS total_sales_no_Null FROM #VideoGamesSales
WHERE
	RankID IS NOT NULL AND
	GameName IS NOT NULL AND 
	Platform_ IS NOT NULL AND
	ReleaseYear IS NOT NULL AND
	Genre IS NOT NULL AND
	Publisher IS NOT NULL AND
	NorthAmerican_Sales	IS NOT NULL AND
	EuropeanUnion_Sales	IS NOT NULL AND
	Japan_Sales	IS NOT NULL AND
	Other_Sales	IS NOT NULL AND
	Global_Sales IS NOT NULL) vgs_no_null
--Percentage Null to all data in global sales is 1.21%

--From checking on point A and B, it's concluded that Null data will be deleted due to not highly impact
--Delete NULL data from temp table VideoGamesSales
DELETE FROM #VideoGamesSales
WHERE 
	RankID IS NULL OR
	GameName IS NULL OR 
	Platform_ IS NULL OR
	ReleaseYear IS NULL OR
	Genre IS NULL OR
	Publisher IS NULL OR
	NorthAmerican_Sales	IS NULL OR
	EuropeanUnion_Sales	IS NULL OR
	Japan_Sales	IS NULL OR
	Other_Sales	IS NULL OR
	Global_Sales IS NULL
	
--Preview the final data in temp table
SELECT * FROM #VideoGamesSales


--5. Last Step, insert to permanent tables, so Power BI can import the data
--a. Insert table video games sales
DROP TABLE IF EXISTS dbo.VideoGamesSales
SELECT *
INTO dbo.VideoGamesSales
FROM #VideoGamesSales


--6. Make table dictionary of platform. 
--Using sources from chat GPT by asking the definition and other data about each platform
--This table dictionary to help explanation of platform code
DROP TABLE IF EXISTS #PlatformExplanation
CREATE TABLE #PlatformExplanation
(
	PlatformCode VARCHAR(10) PRIMARY KEY, PlatformName VARCHAR(50), Manufacturer VARCHAR(50),
	PlatformType VARCHAR(20), ReleaseYear INT, Generation VARCHAR(20),
	PlatformDescription VARCHAR(200)
)

INSERT INTO #PlatformExplanation
(
	PlatformCode, PlatformName, Manufacturer, PlatformType, ReleaseYear, Generation, PlatformDescription
)

VALUES 
( '2600', 'Atari 2600', 'Atari', 'Home Console', 1977, 'Second Generation',
'One of the earliest home video game consoles released by Atari and highly influential in the gaming industry.'),

('3DO', '3DO Interactive Multiplayer', 'The 3DO Company', 'Home Console', 1993, 'Fifth Generation',
'A CD-based gaming console known for advanced multimedia features during the early 1990s.'),

('3DS', 'Nintendo 3DS', 'Nintendo', 'Handheld', 2011, 'Eigth Generation',
'A handheld gaming console featuring glass-free 3D graphics and dual screens.'),

('DC', 'Dreamcast', 'Sega', 'Home Console', 1998, 'Sixth Generation',
'Sega’s final home console and one of the first consoles with built-in online gaming support.'),

('DS', 'Nintendo DS', 'Nintendo', 'Handheld', 2004, 'Seventh Generation',
'A dual-screen handheld console featuring touchscreen interaction and portable gaming.'),

('GB', 'Game Boy', 'Nintendo', 'Handheld', 1989, 'Fourth Generation',
'Nintendo’s iconic portable gaming device that became one of the best-selling handhelds of all time.'),

('GBA', 'Game Boy Advance', 'Nintendo', 'Handheld', 2001, 'Sixth Generation',
'An upgraded Game Boy platform with improved graphics and performance capabilities.'),

('GC', 'Nintendo GameCube', 'Nintendo', 'Home Console', 2001, 'Sixth Generation',
'Nintendo’s compact sixth-generation console recognized for multiplayer and family-friendly games.'),

('GEN', 'Sega Genesis', 'Sega', 'Home Console', 1988, 'Fourth Generation',
'Sega’s popular 16-bit gaming console known for fast-paced arcade-style games.'),

('GG', 'Game Gear', 'Sega', 'Handheld', 1990, 'Fourth Generation',
'Sega’s color handheld gaming system designed to compete with Nintendo Game Boy.'),

('N64', 'Nintendo 64', 'Nintendo', 'Home Console', 1996, 'Fifth Generation',
'A console famous for pioneering 3D gaming and analog controller support.'),

('NES', 'Nintendo Entertainment System', 'Nintendo', 'Home Console', 1983, 'Third Generation',
'Classic 8-bit Nintendo console credited with revitalizing the video game industry.'),

('NG', 'Neo Geo', 'SNK', 'Home Console', 1990, 'Fourth Generation',
'Arcade-quality gaming platform recognized for fighting games and premium hardware.'),

('PC', 'Personal Computer', 'Multiple Manufactures', 'PC Gaming', NULL, 'Multiple Generations',
'A flexible gaming platform supporting a wide range of genres, mods, and online multiplayer experiences. Multiple Released Years.'),

('PCFX', 'PC-FX', 'NEC', 'Home Console', 1994, 'Fifth Generation',
'A Japanese gaming console developed by NEC with strong multimedia and anime-style game support.'),

('PS', 'PlayStation', 'Sony', 'Home Console', 1994, 'Fifth Generation',
'Sony’s first PlayStation console that popularized CD-based gaming worldwide.'),

('PS2', 'PlayStation 2', 'Sony', 'Home Console', 2000, 'Sixth Generation',
'The best-selling video game console of all time with a massive game library.'),

('PS3', 'PlayStation 3', 'Sony', 'Home Console', 2006, 'Seventh Generation',
'Sony console featuring Blu-ray technology and online gaming services.'),

('PS4', 'PlayStation 4', 'Sony', 'Home Console', 2013, 'Eighth Generation',
'A highly successful Sony console focused on online connectivity and high-definition gaming.'),

('PSP', 'PlayStation Portable', 'Sony', 'Handheld', 2004, 'Seventh Generation',
'Sony’s first handheld console offering console-quality portable gaming experiences.'),

('PSV', 'PlayStation Vita', 'Sony', 'Handheld', 2011, 'Eighth Generation',
'Advanced handheld console featuring touchscreen controls and high-performance graphics.'),

('SAT', 'Sega Saturn', 'Sega', 'Home Console', 1994, 'Fifth Generation',
'Sega’s 32-bit console known for strong arcade ports and Japanese game library.'),

('SCD', 'Sega CD', 'Sega', 'Console Add-On', 1991, 'Fourth Generation',
'A CD-ROM add-on for Sega Genesis that expanded storage and multimedia capabilities.'),

('SNES', 'Super Nintendo Entertainment System', 'Nintendo', 'Home Console', 1990, 'Fourth Generation',
'Nintendo’s legendary 16-bit console known for classic RPG and platform games.'),

('TG16', 'TurboGrafx-16', 'NEC', 'Home Console', 1987, 'Fourth Generation',
'A home gaming console recognized for arcade-style graphics and CD-ROM support.'),

('Wii', 'Nintendo Wii', 'Nintendo', 'Home Console', 2006, 'Seventh Generation',
'A motion-controlled console that expanded gaming audiences to casual and family players.'),

('WiiU', 'Wii U', 'Nintendo', 'Home Console', 2012, 'Eighth Generation',
'Nintendo console featuring a tablet-style GamePad controller and dual-screen gameplay.'),

('WS', 'WonderSwan', 'Bandai', 'Handheld', 1999, 'Sixth Generation',
'A Japanese handheld gaming console developed by Bandai with strong anime/game franchise support.'),

('X360', 'Xbox 360', 'Microsoft', 'Home Console', 2005, 'Seventh Generation',
'Microsoft’s popular gaming console known for Xbox Live online services.'),

('XB', 'Xbox', 'Microsoft', 'Home Console', 2001, 'Sixth Generation',
'Microsoft’s first gaming console competing directly with PlayStation and Nintendo.'),

('XOne', 'Xbox One', 'Microsoft', 'Home Console', 2013, 'Eigth Generation',
'A gaming and entertainment console focused on online ecosystems and multimedia integration.')


--Insert table platform explanation
DROP TABLE IF EXISTS dbo.PlatformExplanation
SELECT *
INTO dbo.PlatformExplanation
FROM #PlatformExplanation