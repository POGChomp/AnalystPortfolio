/*

Cleaning data in SQL queries

Project idea: https://www.youtube.com/c/AlexTheAnalyst
Dataset: https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx

*/

SELECT *
FROM PortfolioProjectCleaning..housing_data;


-- NOTICE ----------------------------------------------------------------------------------------------------------------
-- DROPped columns during the process:
-- OwnerAddress, 
-- TaxDistrict, 
-- PropertyAddress, 
-- SaleDate


-- Standardize date foramt -----------------------------------------------------------------------------------------------

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM PortfolioProjectCleaning..housing_data;

-- Did not work
--UPDATE housing_data
--SET SaleDate = CONVERT(DATE, SaleDate);

ALTER TABLE housing_data
ADD SaleDateConverted DATE;

UPDATE housing_data
SET SaleDateConverted = CONVERT(DATE, SaleDate);

SELECT SaleDateConverted, CONVERT(DATE, SaleDate)
FROM PortfolioProjectCleaning..housing_data;


-- Populate property address data ----------------------------------------------------------------------------------------

SELECT PropertyAddress
FROM PortfolioProjectCleaning..housing_data
WHERE PropertyAddress IS NULL;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjectCleaning..housing_data AS a
JOIN PortfolioProjectCleaning..housing_data AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjectCleaning..housing_data AS a
JOIN PortfolioProjectCleaning..housing_data AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


-- Breaking out address into individual columns (address, city, state) ---------------------------------------------------
-- PropertyAddress

SELECT PropertyAddress
FROM PortfolioProjectCleaning..housing_data;

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM PortfolioProjectCleaning..housing_data;

ALTER TABLE housing_data
ADD PropertySplitAddress NVARCHAR(255);

UPDATE housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE housing_data
ADD PropertySplitCity NVARCHAR(255);

UPDATE housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM PortfolioProjectCleaning..housing_data;

-- OwnerAddress

SELECT OwnerAddress
FROM PortfolioProjectCleaning..housing_data;

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProjectCleaning..housing_data;

ALTER TABLE housing_data
ADD OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255);

UPDATE housing_data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProjectCleaning..housing_data;


-- Change Y and N to Yes and No in "Sold as Vacant" field ----------------------------------------------------------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProjectCleaning..housing_data
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END
FROM PortfolioProjectCleaning..housing_data;

UPDATE housing_data
SET SoldAsVacant =
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END;


-- Remove duplicates -----------------------------------------------------------------------------------------------------

WITH RowNumCTE AS (
	SELECT *, 
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertySplitAddress,
					 PropertySplitCity,
					 SalePrice,
					 SaleDateConverted,
					 LegalReference
					 ORDER BY UniqueID) row_num
	FROM PortfolioProjectCleaning..housing_data
)

DELETE
FROM RowNumCTE
WHERE row_num > 1;


-- Delete unused columns -------------------------------------------------------------------------------------------------

ALTER TABLE housing_data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;