    DECLARE @param_dataareaid VARCHAR(20) = 'CI'
    --(Optional)
    DECLARE @param_item VARCHAR(20) = '097015'
    ;
--------------------------------------------------------------------------------------------------------------
/*
Title: Last Price Paid
Description: Provides Last Price Paid for Any Item Passed to Parameter
Parameters:
    Description: Parameters can be copied and pasted outside of comments for SQL Testing
    --(Required)
    DECLARE @param_dataareaid VARCHAR(20) = 'CI'
    --(Optional)
    DECLARE @param_item VARCHAR(20) = 'ALL'
    ;
*/
--------------------------------------------------------------------------------------------------------------

/*
CTE_MAX_REC_ID
Description: Gathers all Max RecIDs From Purchline Table. Max RecID Should be Last Purchline of Specific Item Created.
*/
WITH CTE_MAX_REC_ID AS (

    SELECT 
    
        T.ITEMID
        ,V.CONFIG_ID
        ,V.INVENT_STYLE_ID
        ,MAX(T.RECID) AS MAX_REC_ID
    
    FROM MICROSOFTDYNAMICSAX.DBO.PURCHLINE T 

    LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

        ON V.INVENT_DIM_ID      = T.INVENTDIMID
        AND V.DATA_AREA_ID      = T.DATAAREAID
        AND V.[PARTITION]       = T.[PARTITION]
    
    WHERE 
        
        1=1
        AND T.DATAAREAID        = @param_dataareaid
        AND (T.ITEMID IN (@param_item) OR ('ALL' in (@param_item)))
    
    GROUP BY 
        
        T.ITEMID
        ,V.CONFIG_ID
        ,V.INVENT_STYLE_ID

)


SELECT 
 
    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,T.PURCHPRICE
    ,T.PRICEUNIT
    ,T.CREATEDDATETIME

FROM PURCHLINE T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 
    
    1=1
    AND T.RECID IN (
        
        SELECT 
        
            T.MAX_REC_ID

        FROM CTE_MAX_REC_ID T 
    )