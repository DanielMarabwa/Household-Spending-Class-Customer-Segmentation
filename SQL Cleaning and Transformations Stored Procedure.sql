USE [US_EXPENDITURES]
GO
/****** Object:  StoredProcedure [dbo].[Derive_Household_Features]    Script Date: 12/12/2025 15:26:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER  PROCEDURE [dbo].[Derive_Household_Features]
--AS
---------------------------------------------------- BLOCK ONE ------------------------------------------------------------------------------

/************************************************************
This section of code will focus on reducing the household expenditure to data 
within the same year as the US_EXPENDITURES.DBO.HOUSEHOLDS table. When making predications
we want to only focus on household expenditure within the same year as the Household survery.

If household 20 took a survey in 2018, we only want to include expenditure in 2018 and not in 2019.
This will help us when making predictions on household surveys in other years and reduce complexity.
*************************************************************/

DROP TABLE IF EXISTS #EXPENDITURES

CREATE TABLE #EXPENDITURES (
    EXPENDITURE_ID INT,
    HOUSEHOLD_ID INT, 
    [YEAR] INT,
    [MONTH] INT,
    PRODUCT_CODE INT,
    COST FLOAT,
    GIFT INT,
    IS_TRAINING INT
    PRIMARY KEY (EXPENDITURE_ID) -- This makes sure that there will not be any duplication.
);

INSERT INTO #EXPENDITURES

SELECT E.*
FROM	US_EXPENDITURES.DBO.HOUSEHOLDS AS H

INNER JOIN US_EXPENDITURES.DBO.EXPENDITURES AS E
ON		E.HOUSEHOLD_ID = h.HOUSEHOLD_ID

Where	E.year = H.YEAR -- Make sure that only expenditure done in the same year is included


/*******************************************************************
This Section of the code will focus on extracting new features from the expenditures table. 

1) We will put products into different expenditure bands based on the average cost per product.
2) We will count the number of gifts 

*******************************************************************/



DROP TABLE IF EXISTS #AVERAGE_COST_PER_PRODUCT


CREATE TABLE #AVERAGE_COST_PER_PRODUCT
(
PRODUCT_CODE INT,
TOTAL_SPENT_PER_PRODUCT FLOAT, 
NUMBER_OF_UNITS_BOUGHT INT, 
AVERAGE_COST_PER_PRODUCT FLOAT
PRIMARY KEY (PRODUCT_CODE)
)

INSERT INTO #AVERAGE_COST_PER_PRODUCT
SELECT	PRODUCT_CODE, 
		SUM(COST)										AS TOTAL_SPENT_PER_PRODUCT, 
		COUNT(*)										AS NUMBER_OF_UNITS_BOUGHT, 
		SUM(COST)/COUNT(*)							    AS  AVERAGE_COST_PER_PRODUCT
FROM	US_EXPENDITURES.DBO.EXPENDITURES

group by PRODUCT_CODE


DROP TABLE IF EXISTS #PRODUCT_CODE_EXPENDITURE_BAND

CREATE TABLE  #PRODUCT_CODE_EXPENDITURE_BAND
(
PRODUCT_CODE INT,
EXPENDITURE_BAND VARCHAR(50)
PRIMARY KEY (PRODUCT_CODE)
)

INSERT INTO  #PRODUCT_CODE_EXPENDITURE_BAND 
select  PRODUCT_CODE,
        CASE WHEN AVERAGE_COST_PER_PRODUCT >= 5000 THEN 'BAND_ONE'
             WHEN AVERAGE_COST_PER_PRODUCT >= 500 THEN  'BAND_TWO'
             WHEN AVERAGE_COST_PER_PRODUCT >= 250 THEN  'BAND_THREE'
             WHEN  AVERAGE_COST_PER_PRODUCT >= 100 THEN  'BAND_FOUR'
             WHEN AVERAGE_COST_PER_PRODUCT >= 50 THEN  'BAND_FIVE'
             WHEN AVERAGE_COST_PER_PRODUCT >= 10 THEN  'BAND_SEX'
             WHEN  AVERAGE_COST_PER_PRODUCT > 0 THEN  'BAND_SEVEN'
             ELSE 'NONE' END                            AS EXPENDITURE_BAND
FROM    #AVERAGE_COST_PER_PRODUCT


/****************************************************************
Our final dataset (used to make predictions) will contain one line per household expenditure per year.
Having the expenditure bands per unit purchased will not help us because we need to aggregate the expenditure data at the household level. 
A solution is to convert the Expenditure_BAND column into multiple columns using the pivot function. 
The code below converts each band into its own column. We can then aggregate each band column at the household level.
*****************************************************************/


DROP TABLE IF EXISTS #EXPENDITURE_IDS_WITH_EXPENDITURE_BANDS 

CREATE TABLE #EXPENDITURE_IDS_WITH_EXPENDITURE_BANDS (
    EXPENDITURE_ID INT,
    EXPENDITURE_INDICATOR INT, 
    EXPENDITURE_BAND VARCHAR(50),
    PRIMARY KEY (EXPENDITURE_ID) -- This insures that there will not be any duplication.
);

INSERT INTO #EXPENDITURE_IDS_WITH_EXPENDITURE_BANDS 

SELECT      EXPENDITURE_ID,
            1 as EXPENDITURE_INDICATOR, -- This will allow us to only count each expendture as 1 
            P.EXPENDITURE_BAND
FROM        #EXPENDITURES AS E

LEFT JOIN  #PRODUCT_CODE_EXPENDITURE_BAND AS P
ON         E.PRODUCT_CODE = P.PRODUCT_CODE


DROP TABLE IF EXISTS  #EXPENDITURE_BY_PRODUCT_CODE_BANDS


select EXPENDITURE_ID,
       isnull(BAND_ONE,0)       AS BAND_ONE, 
       ISNULL(BAND_TWO,0)       AS BAND_TWO, 
       ISNULL(BAND_THREE,0)     AS BAND_THREE,
       ISNULL(BAND_FOUR,0)      AS BAND_FOUR,
       ISNULL(BAND_FIVE,0)      AS BAND_FIVE,
       ISNULL(BAND_SEX,0)       AS BAND_SEX,
       ISNULL(BAND_SEVEN,0)     AS BAND_SEVEN
INTO   #EXPENDITURE_BY_PRODUCT_CODE_BANDS
from 
(
  select EXPENDITURE_ID, EXPENDITURE_BAND, EXPENDITURE_INDICATOR
  from #EXPENDITURE_IDS_WITH_EXPENDITURE_BANDS 
) src

pivot
(
    MAX(EXPENDITURE_INDICATOR)
  for EXPENDITURE_BAND in (BAND_ONE, BAND_TWO, BAND_THREE,BAND_FOUR,BAND_FIVE,BAND_SEX,BAND_SEVEN)
) piv;

ALTER TABLE #EXPENDITURE_BY_PRODUCT_CODE_BANDS
ADD CONSTRAINT PK_EXPENDITURE_ID PRIMARY KEY (EXPENDITURE_ID)

--SELECT      *
--FROM         #EXPENDITURE_BY_PRODUCT_CODE_BANDS


DROP TABLE IF EXISTS #UPDATED_EXPENDITURES

CREATE TABLE #UPDATED_EXPENDITURES (
    EXPENDITURE_ID INT,
    HOUSEHOLD_ID INT, 
    [YEAR] INT,
    [MONTH] INT,
    PRODUCT_CODE INT,
    COST FLOAT,
    GIFT INT,
    IS_TRAINING INT, 
    BAND_ONE INT, 
    BAND_TWO INT, 
    BAND_THREE INT, 
    BAND_FOUR INT, 
    BAND_FIVE INT,
    BAND_SEX INT,
    BAND_SEVEN INT
    PRIMARY KEY (EXPENDITURE_ID) -- This makes sure that there will not be any duplication.
);

INSERT INTO #UPDATED_EXPENDITURES

SELECT      e.EXPENDITURE_ID,
             e.HOUSEHOLD_ID,
             e.[YEAR], 
             e.[MONTH],
             e.PRODUCT_CODE,
             e.COST,
             e.GIFT,
             e.IS_TRAINING,
             ecb.BAND_ONE, 
             ecb.BAND_TWO, 
             ecb.BAND_THREE,
             ecb.BAND_FOUR,
             ecb.BAND_FIVE,
             ecb.BAND_SEX,
             ecb.BAND_SEVEN
FROM         #EXPENDITURES AS e

left join   #EXPENDITURE_BY_PRODUCT_CODE_BANDS ecb
on           ecb.EXPENDITURE_ID = e.EXPENDITURE_ID

/******************************************************
We now aggregate the expenditure data on a household and year level.Household ID will be the primary key and year will be included so that
time-based train-test split can be applied.
We remove features that won't be predictive during aggregation, such as expenditure ID, Month, Product_code and IS_training.

*******************************************************/
DROP TABLE IF EXISTS #EXPENDITURE_PER_HOUSEHOLD
CREATE TABLE #EXPENDITURE_PER_HOUSEHOLD
(
HOUSEHOLD_ID INT,
[YEAR] INT,
NUMBER_OF_GIFTS INT,
NUMBER_OF_PURCHASES INT,
BAND_ONE_PURCHASES INT, 
BAND_TWO_PURCHASES INT,
BAND_THREE_PURCHASES INT,
BAND_FOUR_PURCHASES INT, 
BAND_FIVE_PURCHASES INT, 
BAND_SEX_PURCHASES INT,
BAND_SEVEN_PURCHASES INT, 
TOTAL_SPENT FLOAT
PRIMARY KEY (HOUSEHOLD_ID)
)

INSERT INTO  #EXPENDITURE_PER_HOUSEHOLD

SELECT      HOUSEHOLD_ID,
            YEAR,
            SUM(GIFT)                   AS NUMBER_OF_GIFTS,
            COUNT(*)                    AS NUMBER_OF_PURCHASES,
            sum(BAND_ONE)               AS BAND_ONE_PURCHASES, 
            sum(BAND_TWO)               AS BAND_TWO_PURCHASES , 
            sum(BAND_THREE)             AS BAND_THREE_PURCHASES,
            sum(BAND_FOUR)              AS BAND_FOUR_PURCHASES,
            sum(BAND_FIVE)              AS BAND_FIVE_PURCHASES,
            sum(BAND_SEX)               AS BAND_SEX_PURCHASES,
            sum(BAND_SEVEN)             AS BAND_SEVEN_PURCHASES,
            SUM(COST)                   AS TOTAL_SPENT
FROM        #UPDATED_EXPENDITURES

GROUP BY    HOUSEHOLD_ID,
            YEAR

---------------------------------------------------- BLOCK TWO ------------------------------------------------------------------------------
/*******************************************************************************************
In this section of code, we want aggreate the household member data ( US_EXPENDITURES.DBO.HOUSEHOLD_MEMBERS table) onto a household level. This will allow us to predict household
expenditure/
*******************************************************************************************/

/*****************************************************************************************
We want to put all the data in the US_EXPENDITURES.DBO.HOUSEHOLD_MEMBERS table into the temp table  #HOUSEHOLD_MEMBERS 

We also update #HOUSEHOLD_MEMBERS  so that the work status displayed 0 and not'\0' 
If a household member was not a working

We also update table  #HOUSEHOLD_MEMBERS to indicate if a household member has a job (Work_status) and if they are a female. 
******************************************************************************************/

DROP TABLE IF EXISTS  #HOUSEHOLD_MEMBERS 

CREATE TABLE #HOUSEHOLD_MEMBERS 
(
HOUSEHOLD_ID INT, 
[YEAR] INT,
MARITAL INT,
SEX INT,
AGE INT,
WORK_STATUS VARCHAR(5),
--PRIMARY KEY (HOUSEHOLD_ID)
)

INSERT INTO #HOUSEHOLD_MEMBERS 

SELECT  HOUSEHOLD_ID, 
        [YEAR],
        MARITAL,
        SEX,
        AGE,
        WORK_STATUS
FROM    US_EXPENDITURES.DBO.HOUSEHOLD_MEMBERS 

--WHERE    YEAR = @YEAR


UPDATE  #HOUSEHOLD_MEMBERS 
SET WORK_STATUS = 0
where WORK_STATUS = \0

ALTER TABLE #HOUSEHOLD_MEMBERS 
ADD WORKING_OR_NOT INT 

UPDATE #HOUSEHOLD_MEMBERS 
SET WORKING_OR_NOT = 1
WHERE WORK_STATUS > 0

UPDATE #HOUSEHOLD_MEMBERS 
SET WORKING_OR_NOT = 0
WHERE WORK_STATUS = 0

ALTER TABLE #HOUSEHOLD_MEMBERS 
ADD FEMALE_INDICATOR INT 


-- We want to check
UPDATE #HOUSEHOLD_MEMBERS 
SET FEMALE_INDICATOR = 1
WHERE SEX = 2

UPDATE #HOUSEHOLD_MEMBERS 
SET FEMALE_INDICATOR = 0
WHERE SEX = 1


--SELECT      *
--FROM        #HOUSEHOLD_MEMBERS


/***********************************************************************
We now aggregate household members by their households. 
We generate new features such as Household job, number of household members, etc.

*************************************************************************/


DROP TABLE IF EXISTS  #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS 
CREATE TABLE #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS 
(
HOUSEHOLD_ID INT,
YEAR INT,
NUMBER_OF_HOUSEHOLD_JOBS INT,
NUMBER_OF_HOUSEHOLD_MEMBERS_WITH_JOBS INT,
NUMBER_OF_HOUSEHOLD_MEMBERS INT,
NUMBER_OF_FEMALES INT
PRIMARY KEY (HOUSEHOLD_ID)
)

INSERT INTO  #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS 

SELECT      HOUSEHOLD_ID,
            YEAR,
            SUM(CAST(WORK_STATUS AS INT))   AS NUMBER_OF_HOUSEHOLD_JOBS,
            SUM(WORKING_OR_NOT)             AS NUMBER_OF_HOUSEHOLD_MEMBERS_WITH_JOBS,
            COUNT(*)                        AS NUMBER_OF_HOUSEHOLD_MEMBERS,
            SUM(FEMALE_INDICATOR)           AS NUMBER_OF_FEMALES

FROM        #HOUSEHOLD_MEMBERS

GROUP BY    HOUSEHOLD_ID,
            YEAR

--------------------------------------------------------------------- BLOCK THREE ------------------------------------------------------------------------
/****************************************************************************
In this section, we build our final dataset. 

We join the original US_EXPENDITURES.DBO.HOUSEHOLDS table with the #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS and #EXPENDITURE_PER_HOUSEHOLD tables.

The original Household member and expenditure tables underwent a data transformation process to generate #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS 
and #EXPENDITURE_PER_HOUSEHOLD. These new tables were aggregated on a household_ID level and can be linked back to the US_EXPENDITURES.DBO.HOUSEHOLDS table. 
This new set of joins will allow us to combine features from the households,household members and expenditure to predict the annual expenditure for each household.

****************************************************************************/


TRUNCATE TABLE US_EXPENDITURES.DBO.HOUSEHOLDS_DERIVED_FEATURES

INSERT INTO US_EXPENDITURES.DBO.HOUSEHOLDS_DERIVED_FEATURES

SELECT  u.HOUSEHOLD_ID,
        u.[YEAR],
        u.INCOME_RANK,
        u.INCOME_RANK_1,
        u.INCOME_RANK_2,
        u.INCOME_RANK_3,
        u.INCOME_RANK_4,
        u.INCOME_RANK_5,
        u.INCOME_RANK_MEAN,
        u.AGE_REF,
        a.NUMBER_OF_HOUSEHOLD_JOBS,
        a.NUMBER_OF_HOUSEHOLD_MEMBERS_WITH_JOBS,
        a.NUMBER_OF_HOUSEHOLD_MEMBERS,
        a.NUMBER_OF_FEMALES,
        e.NUMBER_OF_GIFTS,
        e.NUMBER_OF_PURCHASES,
        e.BAND_ONE_PURCHASES, 
        e.BAND_TWO_PURCHASES , 
        e.BAND_THREE_PURCHASES,
        e.BAND_FOUR_PURCHASES,
        e.BAND_FIVE_PURCHASES,
        e.BAND_SEX_PURCHASES,
        e.BAND_SEVEN_PURCHASES,
        e.TOTAL_SPENT
FROM     US_EXPENDITURES.DBO.HOUSEHOLDS u

LEFT JOIN       #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS a
ON              a.HOUSEHOLD_ID = U.HOUSEHOLD_ID

INNER JOIN      #EXPENDITURE_PER_HOUSEHOLD e -- We have to inner join because some households did not have expenditure data. We need to make sure that all households have expenditure data before modelling.
ON              e.HOUSEHOLD_ID = U.HOUSEHOLD_ID

--WHERE       U.YEAR = @YEAR

--SELECT  HOUSEHOLD_ID,
--        [YEAR],
--        INCOME_RANK,
--        INCOME_RANK_1,
--        INCOME_RANK_2,
--        INCOME_RANK_3,
--        INCOME_RANK_4,
--        INCOME_RANK_5,
--        INCOME_RANK_MEAN,
--        AGE_REF,
--        NUMBER_OF_HOUSEHOLD_JOBS,
--        NUMBER_OF_HOUSEHOLD_MEMBERS_WITH_JOBS,
--        NUMBER_OF_HOUSEHOLD_MEMBERS,
--        NUMBER_OF_FEMALES,
--        NUMBER_OF_GIFTS,
--        NUMBER_OF_PURCHASES,
--        BAND_ONE_PURCHASES, 
--        BAND_TWO_PURCHASES , 
--        BAND_THREE_PURCHASES,
--        BAND_FOUR_PURCHASES,
--        BAND_FIVE_PURCHASES,
--        BAND_SEX_PURCHASES,
--        BAND_SEVEN_PURCHASES,
--        TOTAL_SPENT
--FROM    US_EXPENDITURES.DBO.HOUSEHOLDS_DERIVED_FEATURES
/******************************************************
We drop all temporary tables at the end of the stored procedure. This allows us to run it continuously without incurring errors. 
If we update or alter a temporary table and re-run the code without first dropping all of them, 
it will cause errors because the tables have already been modified.
*******************************************************/

DROP TABLE IF EXISTS #HOUSEHOLD_MEMBERS 
DROP TABLE IF EXISTS #EXPENDITURES
DROP TABLE IF EXISTS #AVERAGE_COST_PER_PRODUCT
DROP TABLE IF EXISTS #PRODUCT_CODE_EXPENDITURE_BAND
DROP TABLE IF EXISTS #EXPENDITURE_IDS_WITH_EXPENDITURE_BANDS 
DROP TABLE IF EXISTS #EXPENDITURE_BY_PRODUCT_CODE_BANDS
DROP TABLE IF EXISTS #UPDATED_EXPENDITURES
DROP TABLE IF EXISTS #EXPENDITURE_PER_HOUSEHOLD
DROP TABLE IF EXISTS  #HOUSEHOLD_MEMBERS 
DROP TABLE IF EXISTS  #HOUSEHOLDS_BY_HOUSEHOLD_MEMBERS 

