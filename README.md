# Household-Spending-Class-Customer-Segmentation

## Purpose
The purpose of this project is to use U.S. Census Bureau survey data to predict the spending class of a particular household. This project represents a hypothetical scenario in which I am building a data product for a data science company. Model deployment is beyond the scope of this project. Our final solution will need to integrate Data Engineering, Data Analytics, and Data Science to transform the source data (CSV) into a final model. SQL and Python will be used to build our model. 

Our company will build a machine learning model that predicts the spending class of a household. Our company aims to build a similar survey (to the U.S. Bureau survey) that generates the same input features, which will feed into our data pipelines, database**,** and model. The survey, data process, and model will be our product, which we can then license to other companies so they can identify the spending class a household belongs to. Our product will allow other companies to risk-profile their own clients and recommend certain products that suit their spending habits.

## Data 
The US Bureau asked collected household data on spending, income thresholds and general information about each household. The source of the data was extracted in 3 csv files: "Expenditures.csv", "HOUSEHOLD_MEMBERS.csv", and "HOUSEHOLDS.csv". The three data sources will be intergrated into a final derived Please section Data Description for a detailed description of the original data sources. 

## Client Requirements and Design Constraints

1) A key concern raised by our clients (companies using our product) is the potential 
for customer spending habits to change over time. 

 To directly address this crucial concern and ensure the model is reliable for future efforts, 
 we must use a time-based train-test split. The data used to train the model will be on a 
 timeline prior to the data used to test the model’s performance.  

2) Another design constraint is that although the original US bureau included the amount of 
money each product cost, it would be impractical to expect individuals (taking the survey) 
to remember the price of each product, instead as part of the data process, different 
products (purchased by households) will be placed into different bands based on the 
average price of the product they bought. 

3) Our clients would ideally like a model that is explainable so they can understand why it 
makes certain decisions. However, this is not a critical requirement and should not come 
at the cost of building a poor-performing model.
