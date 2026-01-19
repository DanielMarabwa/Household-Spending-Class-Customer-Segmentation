# Household-Spending-Class-Customer-Segmentation

## Purpose
The purpose of this project is to use U.S. Census Bureau survey data to predict the spending class of a particular household. This project represents a hypothetical scenario in which I am building a data product for a data science company. Model deployment is beyond the scope of this project. Our final solution will need to integrate Data Engineering, Data Analytics, and Data Science to transform the source data (CSV) into a final model. SQL and Python will be used to build our model. 

Our company will build a machine learning model that predicts the spending class of a household.The survey, data process, and model will be our product, which we can then license to other companies so they can identify the spending class a household belongs to. Our product will allow other companies to risk-profile their own clients and recommend certain products that suit their spending habits.

## Data 
The US Bureau collected household data on spending, income thresholds, and general information about each household. The source data was extracted from three CSV files: "Expenditures.csv", "HOUSEHOLD_MEMBERS.csv", and "HOUSEHOLDS.csv". These three data sources will be integrated into a final derived household dataset "Derived_Household_Features.csv", which will be used for the Python EDA and model build. Please see the **"Data Description"** section for a detailed description of the original data sources.

## Client Requirements and Design Constraints

1) A key concern raised by our clients (companies using our product) is the potential 
for customer spending habits to change over time.To directly address this crucial concern and ensure the model is reliable for future efforts, we must use a time-based train-test split. The data used to train the model will be on a timeline prior to the data used to test the model’s performance.  

2) Another design constraint is that although the original US bureau included the amount of 
money each product cost, it would be impractical to expect individuals (taking the survey) 
to remember the price of each product, instead as part of the data process, different 
products (purchased by households) will be placed into different bands based on the 
average price of the product they bought. 

3) Our clients would ideally like a model that is explainable so they can understand why it 
makes certain decisions. However, this is not a critical requirement and should not come 
at the cost of building a poor-performing model.

## High level Summary of Architectural Flow Diagram

<img width="449" height="299" alt="Architectural Diagram _H" src="https://github.com/user-attachments/assets/f61ae30e-673d-44d7-bf2b-42c4aa886c8f" />

In the figure above, we can see the architectural diagram of this project. This shows the flow of data throughout the project. This process can be described in the following steps. 

Extract, Transform, and Load (ETL) into SQL Tables: Extract CSV files, convert them into dataframes, and load them into SQL Server tables. 

Data Transformations, Cleaning, and SQL Exploratory Data Analysis (EDA): Implement EDA and data manipulation on original tables. 

Data Integration: Link the final SQL Table back to a Python dataframe. 

Python EDA and Optimization Techniques: Implement EDA, apply feature reduction methods, perform hyperparameter tuning, and carry out data preprocessing. 

Model Building and Evaluation: Build models and evaluate the performance of each model. 


## Code 

The code is split into 4 parts 

**Part 1: "Integrated Code - Python and SQL"** 

Prerequisites: Requires the following CSV files: "Expenditures.csv", "HOUSEHOLD_MEMBERS.csv", and "HOUSEHOLDS.csv"

This code provides the end-to-end implementation of this project, starting from the original CSV files (Households, Household_members, and Expenditures) up to the final model performance values.

This Notebook covers the following stages:

1) ETL (Extract, Transform, Load): Extraction of CSV files and loading of data into SQL tables.

2) SQL Table Creation: This notebook triggers a stored procedure that drops and re-creates all necessary tables.

Note: Data checks were implemented in the notebook to confirm that tables were empty prior to loading data.

3) SQL Data Cleaning and Transformations: This notebook triggers a stored procedure that performs data cleaning and generates the final derived table via SQL transformations.

Note: Data checks were implemented in the notebook to confirm the derived table was empty before triggering the stored procedure for data cleaning and transformation.

4) Data Integration: The final derived table (US_EXPENDITURES.DBO.HOUSEHOLDS_DERIVED_FEATURES) is converted into a Python DataFrame (df).

5) Python EDA, Optimization, and Model Build: This notebook implements the exploratory data analysis (EDA), optimization, and model building using Python.


**Part 2: "EDA and Model Build - Python"**

Prerequisites: Requires the following CSV files: "Derived_Household_Features.csv"
The "Derived_Household_Features.csv" has the same data that was built in the SQL Data Cleaning and Transformations process. 

This notebook implements the Python exploratory data analysis (EDA), optimization, and model building using Python and can be implemented on any python environment. 

**Part 3: "SQL Drop and Create tables Stored Procedure"** 

Prerequisites: Requires the following SQL Server configuration:

server = 'DESKTOP-M8H3JN9\SQLEXPRESS' -- Use your own server

database = 'US_EXPENDITURES' -- Use your own database

username = 'username' -- You have to use your own username. 

password = 'password' -- You have to use your own password. 

TrustServerCertificate = 'yes'

SQL SERVER Authentication

This code displays the stored procedure that is used to drop and re-create all necessary tables for the implementation of this project. 


**Part 4: "SQL Cleaning and Transformations Stored Procedure"**

Prerequisites: Requires the following SQL Server configuration:

server = 'DESKTOP-M8H3JN9\SQLEXPRESS' -- Use your own server

database = 'US_EXPENDITURES' -- Use your own database

username = 'username' -- You have to use your own username. 

password = 'password'  -- You have to use your own password. 

TrustServerCertificate = 'yes'

SQL SERVER Authentication

This code displays the stored procedure that is used to perform data cleaning and generate the final derived table via SQL transformations.





