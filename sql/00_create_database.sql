/*
00_create_database.sql

Run this first in SQL Server Management Studio.
*/

IF DB_ID('ManagedCarePortfolio') IS NULL
BEGIN
    CREATE DATABASE ManagedCarePortfolio;
END;
GO

USE ManagedCarePortfolio;
GO