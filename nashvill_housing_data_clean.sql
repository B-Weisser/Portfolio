/* cleaning & prepping data in SQL 
*/


-- taking a look at the data
select * from nashville;

-- number of rows
select count(*) as numrows
 from nashville;
 
 -- making sure UniqueID is indeed unique and thus there are also no duplicates
 select count(distinct UniqueID) from nashville;


/* first field to check: Property Address - seperating street and city */

select count(PropertyAddress) from nashville where PropertyAddress =""; -- 29 missing values, I'll take a closer look later

-- PropertyAddress should have exactly one comma, counting all of them
select sum(LENGTH(PropertyAddress) - LENGTH(REPLACE(PropertyAddress, ',', ''))-1) as commasurplus from nashville where PropertyAddress !=""; 

-- splitting PropertyAddress in two before and after comma
SELECT
SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress) -1 ) as StreetAddress
, SUBSTRING(PropertyAddress, POSITION(',' in PropertyAddress) + 1 , LENGTH(PropertyAddress)) as CityAddress From nashville;


-- adding Property Street Column
ALTER TABLE nashville
Add PropertyStreet VARCHAR(255);

-- adding values
Update nashville 
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress) -1 ) where PropertyAddress !="";

-- adding Property City
ALTER TABLE nashville
Add PropertyCity VARCHAR(255);

-- adding values
Update nashville 
SET PropertyCity = SUBSTRING(PropertyAddress, POSITION(',' in PropertyAddress) + 1 , LENGTH(PropertyAddress)) where PropertyAddress !="";


-- there are a few missing values, and there are indications that identical ParcelIDs have the same address, so let's make sure that is true over all data
-- checking if city is identical - counting the number of addresses per ParcelID to see if there are more than one
 
 select count(distinct sub.propertyperparcel) from ( select ParcelID, count( PropertyAddress)-1 as propertyperparcel from nashville where PropertyAddress !="" group by ParcelID) sub where sub.propertyperparcel>0;

/* some parcels have up to 3 addresses, so we can't use that to replace the missing values. Depending on what we will do with the data, I'd either 
delete those lines completly:
DELETE FROM nashville where PropertyAddress !="";

replace it with 'UNKNOWN':
Update nashville 
SET PropertyCity = 'UNKNOWN' where PropertyAddress !="";
Update nashville 
SET PropertyStreet = 'UNKNOWN' where PropertyAddress !="";


or just leave it blank 

Let's pretend for the sake of this project that ParcelIDs are only associated with one address. Then we could fill those missing values as seen below.*/

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From nashville a
JOIN nashville b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID  <> b.UniqueID 
Where a.PropertyAddress ="";

Select ParcelID, PropertyAddress from nashville where ParcelID ='025 07 0 031.00'; -- sample check to see the result above is correct

-- update table with Property City from other rows with same Parcel ID
Update nashville as a
JOIN nashville b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID  <> b.UniqueID 
SET a.PropertyCity = b.PropertyCity
Where a.PropertyAddress ="";

-- update table with Property Street from other rows with same Parcel ID
Update nashville as a
JOIN nashville b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID  <> b.UniqueID 
SET a.PropertyStreet = b.PropertyStreet
Where a.PropertyAddress ="";

Select PropertyAddress, PropertyStreet, PropertyCity from nashville where PropertyAddress="";


/* Doing the same for Owner Address, but that one comes with Street,City,State, so two commas */

select count(OwnerAddress) from nashville where OwnerAddress =""; -- 30462 missing values, I'll take a closer look later

-- PropertyAddress should have exactly two comma, counting all of them
select sum(LENGTH(OwnerAddress) - LENGTH(REPLACE(OwnerAddress, ',', ''))-2) as commasurplus from nashville where OwnerAddress !=""; 

-- splitting PropertyAddress in 3 before and after comma

SELECT
SUBSTRING(OwnerAddress, 1, POSITION(',' in OwnerAddress) -1 ) as OwnerStreet, 
SUBSTRING(OwnerAddress, POSITION(',' in OwnerAddress) + 1 , LENGTH(OwnerAddress)-POSITION(',' in REVERSE(OwnerAddress))-POSITION(',' in OwnerAddress)) as OwnerCity,
substring(OwnerAddress, LENGTH(OwnerAddress)+2-POSITION(',' in REVERSE(OwnerAddress)),LENGTH(OwnerAddress)) as OwnerState 
From nashville  where OwnerAddress !="";


-- adding Owner Street Column
ALTER TABLE nashville
Add OwnerStreet VARCHAR(255);

-- adding values
Update nashville 
SET OwnerStreet = SUBSTRING(OwnerAddress, 1, POSITION(',' in OwnerAddress) -1)  where OwnerAddress !="";

-- adding Owner City Column
ALTER TABLE nashville
Add OwnerCity VARCHAR(255);

-- adding values
Update nashville 
SET OwnerCity = SUBSTRING(OwnerAddress, POSITION(',' in OwnerAddress) + 1 , LENGTH(OwnerAddress)-POSITION(',' in REVERSE(OwnerAddress))-POSITION(',' in OwnerAddress))  where OwnerAddress !="";

-- adding Owner State Column
ALTER TABLE nashville
Add OwnerState VARCHAR(255);

-- adding values
Update nashville 
SET OwnerState = substring(OwnerAddress, LENGTH(OwnerAddress)+2-POSITION(',' in REVERSE(OwnerAddress)),LENGTH(OwnerAddress))  where OwnerAddress !="";



-- change Sale Date from string format 'Month day, Year' to date format 'mm-dd-yyyy'

SELECT count(SaleDate) FROM nashville WHERE SaleDate = ""; -- no missing values

-- update date

Update nashville
SET SaleDate = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %e,%Y'),'%m-%d-%Y');




-- "Sold as Vacant" has the values Yes, No, Y, N. I'll change Y&N to Yes&No

Update nashville
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;


-- making sure it worked
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From nashville
Group by SoldAsVacant
order by 2;


/* Finding duplicate records, while we establishes that UniqueID is indeed unique, let's see if we find records with identical ParcelID, PropertyAddress, SaleDate, SalePrice and LegalReference */

-- finding duplicates

SELECT 
	UniqueID
FROM (
	SELECT 
		UniqueID,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
	FROM 
		nashville
) t
WHERE 
	row_num > 1;
    
-- removing duplicates
 
    DELETE FROM nashville 
WHERE 
	UniqueID IN (
	SELECT 
		UniqueID 
	FROM (
		SELECT 
			UniqueID,
			ROW_NUMBER() OVER (
				PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
		FROM 
			nashville
		
	) t
    WHERE row_num > 1
);


-- double checking
SELECT 
	UniqueID
FROM (
	SELECT 
		UniqueID,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
	FROM 
		nashville
) t
WHERE 
	row_num > 1;

