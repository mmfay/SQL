-----------------------------------------------------------------------------------------------------------
/*
Title: Inventory Aging
Description: Calculates Aging Inventory by Entity. Defined all the way down to the location. 
Parameters:
    Description: Parameters can be copied and pasted outside of comments for SQL Testing
    
    --(Required)
    DECLARE @param_p1_UB        INT         = 30  -- Groups Aging Inventory Between 0 - 30 Days.           
    DECLARE @param_p2_UB        INT         = 60  -- Groups Aging Inventory Between 31 - 60 Days. 
    DECLARE @param_p3_UB        INT         = 90  -- Groups Aging Inventory Between 61 - 90 Days. 
    DECLARE @param_p4_UB        INT         = 120  -- Groups Aging Inventory Between 91 - 120 Days. Rest of Inventory Falls Under 120+ Days. 
    DECLARE @param_dataareaid   VARCHAR(20) = 'CI' -- Select Entity for Which Calc Should Run On.
    --(Optional)
    DECLARE @param_itemid       VARCHAR(20) = 'ALL' -- Could Just Look at Item or List of Items. ALL Items are Default.
    DECLARE @param_warehouse    VARCHAR(20) = 'ALL' -- Could Just Look at Warehouse or List of Warehouses. ALL Warehouses are Default.
    DECLARE @param_location     VARCHAR(20) = 'ALL' -- Could Just Look at Location or List of Locations. ALL Locations are Default.
    ;
*/
-----------------------------------------------------------------------------------------------------------

/*
CTE_STARTING_INVENTORY 
DEFINITION: Sums Invent Trans by location excludes any records w/o physical date stamp.
*/
WITH CTE_STARTING_INVENTORY as (

SELECT 

    T.ITEMID
    ,V.CONFIG_ID 
    ,V.INVENT_STYLE_ID
    ,v.INVENT_LOCATION_ID
    ,V.WMS_LOCATION_ID
    ,SUM(T.QTY) AS QTY
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM MICROSOFTDYNAMICSAX.DBO.INVENTTRANS T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 

    1=1
    AND T.DATAAREAID                                    = @param_dataareaid
    AND (V.INVENT_LOCATION_ID IN (@param_warehouse) 	OR ('ALL' IN (@param_warehouse)))
    AND (T.ITEMID IN (@param_itemid) 	                OR ('ALL' IN (@param_itemid)))
    AND (V.WMS_LOCATION_ID IN (@param_location) 	    OR ('ALL' IN (@param_location)))
    AND T.DATEPHYSICAL                                  <> '1900-01-01'

GROUP BY 

    T.ITEMID
    ,V.CONFIG_ID 
    ,V.INVENT_STYLE_ID
    ,v.INVENT_LOCATION_ID
    ,V.WMS_LOCATION_ID
    ,T.DATAAREAID
    ,T.[PARTITION] 

HAVING SUM(T.QTY) > 0

), 
/*
CTE_PARAM_1
DEFINITION: CALCULATES AGED INVENTORY QTY FROM TODAY MINUS PARAMETER 1. ONLY LOOKS AT POSITIVE VALUES ENTERING LOCATION.
*/
CTE_PARAM_1 AS (

SELECT 

    T.ITEMID
    ,v.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,sum(t.QTY) as qty 
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM INVENTTRANS T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 

    1=1
    AND T.DATAAREAID                                    = @param_dataareaid
    AND (V.INVENT_LOCATION_ID IN (@param_warehouse) 	OR ('ALL' IN (@param_warehouse)))
    AND (T.ITEMID IN (@param_itemid) 	                OR ('ALL' IN (@param_itemid)))
    AND V.WMS_LOCATION_ID                               <> ''
    AND CONVERT(DATE,T.DATEPHYSICAL)                    >= CONVERT(DATE,GETDATE()-@param_p1_UB)
    AND T.QTY                                           > 0
    AND (V.WMS_LOCATION_ID IN (@param_location) 	    OR ('ALL' IN (@param_location)))

GROUP BY 

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,V.WMS_LOCATION_ID
    ,T.DATAAREAID
    ,T.[PARTITION] 

),
/*
CTE_PARAM_2
DEFINITION: CALCULATES AGED INVENTORY QTY FROM END OF PERIOD OF PARAM 1 MINUS PARAMETER 2. ONLY LOOKS AT POSITIVE VALUES ENTERING LOCATION.
*/
CTE_PARAM_2 AS (

SELECT 

    T.ITEMID
    ,v.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,sum(t.QTY) as qty 
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM INVENTTRANS T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 

    1=1
    AND T.DATAAREAID                                    = @param_dataareaid
    AND (V.INVENT_LOCATION_ID IN (@param_warehouse) 	OR ('ALL' IN (@param_warehouse)))
    AND (T.ITEMID IN (@param_itemid) 	                OR ('ALL' IN (@param_itemid)))
    AND V.WMS_LOCATION_ID                               <> ''
    AND CONVERT(DATE,T.DATEPHYSICAL)                    < CONVERT(DATE,GETDATE()-@param_p1_UB)
    AND CONVERT(DATE,T.DATEPHYSICAL)                    >= CONVERT(DATE,GETDATE()-@param_p2_UB)
    AND T.QTY                                           > 0    
    AND (V.WMS_LOCATION_ID IN (@param_location) 	    OR ('ALL' IN (@param_location)))

GROUP BY 

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,V.WMS_LOCATION_ID
    ,T.DATAAREAID
    ,T.[PARTITION] 

),
/*
CTE_PARAM_3
DEFINITION: CALCULATES AGED INVENTORY QTY FROM END OF PERIOD OF PARAM 2 MINUS PARAMETER 3. ONLY LOOKS AT POSITIVE VALUES ENTERING LOCATION.
*/
CTE_PARAM_3 AS (

SELECT 

    T.ITEMID
    ,v.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,sum(t.QTY) as qty 
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM INVENTTRANS T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 

    1=1
    AND T.DATAAREAID                                    = @param_dataareaid
    AND (V.INVENT_LOCATION_ID IN (@param_warehouse) 	OR ('ALL' IN (@param_warehouse)))
    AND (T.ITEMID IN (@param_itemid) 	                OR ('ALL' IN (@param_itemid)))
    AND V.WMS_LOCATION_ID                               <> ''
    AND CONVERT(DATE,T.DATEPHYSICAL)                    < CONVERT(DATE,GETDATE()-@param_p2_UB)
    AND CONVERT(DATE,T.DATEPHYSICAL)                    >= CONVERT(DATE,GETDATE()-@param_p3_UB)
    AND T.QTY                                           > 0    
    AND (V.WMS_LOCATION_ID IN (@param_location) 	    OR ('ALL' IN (@param_location)))

group by 

    T.ITEMID
    ,v.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,T.DATAAREAID
    ,T.[PARTITION] 

),
/*
CTE_PARAM_4
DEFINITION: CALCULATES AGED INVENTORY QTY FROM END OF PERIOD OF PARAM 3 MINUS PARAMETER 4. ONLY LOOKS AT POSITIVE VALUES ENTERING LOCATION.
*/
CTE_PARAM_4 AS (

SELECT 

    T.ITEMID
    ,v.CONFIG_ID
    ,v.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,sum(t.QTY) as qty 
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM INVENTTRANS T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 

    1=1
    AND T.DATAAREAID                                    = @param_dataareaid
    AND (V.INVENT_LOCATION_ID IN (@param_warehouse) 	OR ('ALL' IN (@param_warehouse)))
    AND (T.ITEMID IN (@param_itemid) 	                OR ('ALL' IN (@param_itemid)))
    AND V.WMS_LOCATION_ID                               <> ''
    AND CONVERT(DATE,T.DATEPHYSICAL)                    < CONVERT(DATE,GETDATE()-@param_p3_UB)
    AND CONVERT(DATE,T.DATEPHYSICAL)                    >= CONVERT(DATE,GETDATE()-@param_p4_UB)
    AND T.QTY                                           > 0    
    AND (V.WMS_LOCATION_ID IN (@param_location) 	    OR ('ALL' IN (@param_location)))

group by 

    T.ITEMID
    ,v.CONFIG_ID
    ,v.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,T.DATAAREAID
    ,T.[PARTITION] 

),
/*
CTE_PARAM_5
DEFINITION: CALCULATES AGED INVENTORY QTY FROM END OF PERIOD OF PARAM 4. ONLY LOOKS AT POSITIVE VALUES ENTERING LOCATION.
*/
CTE_PARAM_5 AS (

SELECT

    T.ITEMID
    ,v.CONFIG_ID
    ,v.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,sum(t.QTY) as qty 
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM INVENTTRANS T 

LEFT JOIN AXManagement.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID      = T.INVENTDIMID
    AND V.DATA_AREA_ID      = T.DATAAREAID
    AND V.[PARTITION]       = T.[PARTITION]

WHERE 

    1=1
    AND T.DATAAREAID                                    = @param_dataareaid
    AND (V.INVENT_LOCATION_ID IN (@param_warehouse) 	OR ('ALL' IN (@param_warehouse)))
    AND (T.ITEMID IN (@param_itemid) 	                OR ('ALL' IN (@param_itemid)))
    AND V.WMS_LOCATION_ID                               <> ''
    AND CONVERT(DATE,T.DATEPHYSICAL)                    < CONVERT(DATE,GETDATE()-@param_p4_UB)
    AND T.QTY                                           > 0  
    AND (V.WMS_LOCATION_ID IN (@param_location) 	    OR ('ALL' IN (@param_location)))

group by 

    T.ITEMID
    ,v.CONFIG_ID
    ,v.INVENT_STYLE_ID
    ,v.WMS_LOCATION_ID
    ,T.DATAAREAID
    ,T.[PARTITION] 

),
/*
CTE_FINAL
DEFINITION: INVENTORY WORKS OFF FIFO. 
PERIOD CALC = PREVIOUS BALANCE MINUS PERIOD SUM
*/
CTE_P1 AS (

SELECT 

    T.ITEMID
    ,T.CONFIG_ID
    ,t.INVENT_STYLE_ID
    ,t.INVENT_LOCATION_ID
    ,T.WMS_LOCATION_ID
    ,T.QTY
    ,COALESCE(P1.qty,0) AS P1QTY
    -----------P1 AGED QTY
    ,IIF(
        (T.QTY - COALESCE(P1.qty,0)) > 0,
        COALESCE(P1.qty,0),
        T.QTY
    ) AS P1_AGED_QTY
    ---------------------
    -----------P1 BALANCE QTY
    ,IIF(
        (T.QTY - COALESCE(P1.qty,0)) > 0,
        (T.QTY - COALESCE(P1.qty,0)),
        0
    ) AS BALANCE_QTY_P1
    -------------------------
    ,T.DATAAREAID
    ,T.[PARTITION] 

FROM CTE_STARTING_INVENTORY T  

LEFT JOIN CTE_PARAM_1 P1 

    ON T.ITEMID             = P1.ITEMID
    AND T.CONFIG_ID         = P1.CONFIG_ID
    and t.INVENT_STYLE_ID   = p1.INVENT_STYLE_ID
    AND T.WMS_LOCATION_ID   = P1.WMS_LOCATION_ID
    AND T.DATAAREAID        = P1.DATAAREAID
    AND T.[PARTITION]       = P1.[PARTITION]
),

CTE_P2 AS (

    SELECT 
        T.ITEMID
        ,T.CONFIG_ID
        ,t.INVENT_STYLE_ID
        ,t.INVENT_LOCATION_ID
        ,T.WMS_LOCATION_ID
        ,T.QTY
        ,T.P1QTY
        ,T.P1_AGED_QTY
        ,T.BALANCE_QTY_P1
        ,COALESCE(P2.QTY,0) AS P2QTY
        ,IIF(
            (T.BALANCE_QTY_P1 - COALESCE(P2.QTY,0)) > 0,
            COALESCE(P2.QTY,0),
            T.BALANCE_QTY_P1
        ) AS P2_AGED_QTY
        ,IIF (
            (T.BALANCE_QTY_P1 - COALESCE(P2.QTY,0)) > 0,
            (T.BALANCE_QTY_P1 - COALESCE(P2.QTY,0)),
            0
        ) AS BALANCE_QTY_P2
        ,T.DATAAREAID
        ,T.PARTITION

    FROM CTE_P1 T 

    LEFT JOIN CTE_PARAM_2 P2 

        ON T.ITEMID             = P2.ITEMID
        AND T.CONFIG_ID         = P2.CONFIG_ID
        and t.INVENT_STYLE_ID   = p2.INVENT_STYLE_ID
        AND T.WMS_LOCATION_ID   = P2.WMS_LOCATION_ID
        AND T.DATAAREAID        = P2.DATAAREAID
        AND T.[PARTITION]       = P2.[PARTITION]
    
),
CTE_P3 AS (

    SELECT 
        T.ITEMID
        ,T.CONFIG_ID
        ,t.INVENT_STYLE_ID
        ,t.INVENT_LOCATION_ID
        ,T.WMS_LOCATION_ID
        ,T.QTY
        ,T.P1QTY
        ,T.P1_AGED_QTY
        ,T.BALANCE_QTY_P1
        ,T.P2QTY
        ,T.P2_AGED_QTY
        ,T.BALANCE_QTY_P2
        ,COALESCE(P3.QTY,0) AS P3QTY
        ,IIF(
            (T.BALANCE_QTY_P2 - COALESCE(P3.QTY,0)) > 0,
            COALESCE(P3.QTY,0),
            T.BALANCE_QTY_P2
        ) AS P3_AGED_QTY
        ,IIF (
            (T.BALANCE_QTY_P2 - COALESCE(P3.QTY,0)) > 0,
            (T.BALANCE_QTY_P2 - COALESCE(P3.QTY,0)),
            0
        ) AS BALANCE_QTY_P3
        ,T.DATAAREAID
        ,T.PARTITION

    FROM CTE_P2 T 

    LEFT JOIN CTE_PARAM_3 P3 

        ON T.ITEMID             = P3.ITEMID
        AND T.CONFIG_ID         = P3.CONFIG_ID
        and t.INVENT_STYLE_ID   = P3.INVENT_STYLE_ID
        AND T.WMS_LOCATION_ID   = P3.WMS_LOCATION_ID
        AND T.DATAAREAID        = P3.DATAAREAID
        AND T.[PARTITION]       = P3.[PARTITION]
    
),
CTE_P4 AS (

    SELECT 
        T.ITEMID
        ,T.CONFIG_ID
        ,t.INVENT_STYLE_ID
        ,t.INVENT_LOCATION_ID
        ,T.WMS_LOCATION_ID
        ,T.QTY
        ,T.P1QTY
        ,T.P1_AGED_QTY
        ,T.BALANCE_QTY_P1
        ,T.P2QTY
        ,T.P2_AGED_QTY
        ,T.BALANCE_QTY_P2
        ,T.P3QTY 
        ,T.P3_AGED_QTY
        ,T.BALANCE_QTY_P3
        ,COALESCE(P4.QTY,0) AS P4QTY
        ,IIF(
            (T.BALANCE_QTY_P3 - COALESCE(P4.QTY,0)) > 0,
            COALESCE(P4.QTY,0),
            T.BALANCE_QTY_P3
        ) AS P4_AGED_QTY
        ,IIF (
            (T.BALANCE_QTY_P3 - COALESCE(P4.QTY,0)) > 0,
            (T.BALANCE_QTY_P3 - COALESCE(P4.QTY,0)),
            0
        ) AS BALANCE_QTY_P4
        ,T.DATAAREAID
        ,T.PARTITION

    FROM CTE_P3 T 

    LEFT JOIN CTE_PARAM_4 P4 

        ON T.ITEMID             = P4.ITEMID
        AND T.CONFIG_ID         = P4.CONFIG_ID
        and t.INVENT_STYLE_ID   = P4.INVENT_STYLE_ID
        AND T.WMS_LOCATION_ID   = P4.WMS_LOCATION_ID
        AND T.DATAAREAID        = P4.DATAAREAID
        AND T.[PARTITION]       = P4.[PARTITION]
    
),
CTE_P5 AS (

    SELECT 
        T.ITEMID
        ,T.CONFIG_ID
        ,t.INVENT_STYLE_ID
        ,t.INVENT_LOCATION_ID
        ,T.WMS_LOCATION_ID
        ,T.QTY
        ,T.P1QTY
        ,T.P1_AGED_QTY
        ,T.BALANCE_QTY_P1
        ,T.P2QTY
        ,T.P2_AGED_QTY
        ,T.BALANCE_QTY_P2
        ,T.P3QTY 
        ,T.P3_AGED_QTY
        ,T.BALANCE_QTY_P3
        ,T.P4QTY 
        ,T.P4_AGED_QTY
        ,T.BALANCE_QTY_P4
        ,COALESCE(P5.QTY,0) AS P5QTY
        ,IIF(
            (T.BALANCE_QTY_P4- COALESCE(P5.QTY,0)) > 0,
            COALESCE(P5.QTY,0),
            T.BALANCE_QTY_P4
        ) AS P5_AGED_QTY
        ,IIF (
            (T.BALANCE_QTY_P4 - COALESCE(P5.QTY,0)) > 0,
            (T.BALANCE_QTY_P4 - COALESCE(P5.QTY,0)),
            0
        ) AS BALANCE_QTY_P5
        ,T.DATAAREAID
        ,T.PARTITION

    FROM CTE_P4 T 

    LEFT JOIN CTE_PARAM_5 P5 

        ON T.ITEMID             = P5.ITEMID
        AND T.CONFIG_ID         = P5.CONFIG_ID
        and t.INVENT_STYLE_ID   = P5.INVENT_STYLE_ID
        AND T.WMS_LOCATION_ID   = P5.WMS_LOCATION_ID
        AND T.DATAAREAID        = P5.DATAAREAID
        AND T.[PARTITION]       = P5.[PARTITION]
    
),
------------------------------------------------------------------------------
    /*
    --AGED QTY DEFINTION
        IF PREVIOUS BALANCE MINUS PERIOD QTY IS GREATER THAN 0, 
            PERIOD QTY, 
            PREVIOUS BALANCE
    */ 
    /* FORMULA TEMPLATE
        [REPLACE W/ PREVIOUS BALANCE FORMULA],
        [PERIOD QTY ALIAS],
        [PREVIOUS BALANCE]
    */
    ----------------------------
    /* 
    --BALANCE QTY DEFINTION
        IF PREVIOUS BALANCE  MINUS PERIOD QTY IS GREATER THAN 0,
            PREVIOUS BALANCE - PERIOD QTY,
            0 
    */
        /* FORMULA TEMPLATE
        [REPLACE W/ PREVIOUS BALANCE FORMULA],
        [PREVIOUS BALANCE - PERIOD QTY ALIAS],
        0
    */
------------------------------------------------------------------------------



/*
CTE_INVENT_COST
DEFINITION: GATHERS INVENTORY VALUE
*/
CTE_INVENT_COST AS (

SELECT 

    V.ITEM_ID
    ,V.CONFIG_ID
    ,v.INVENT_STYLE_ID
    ,V.INVENT_LOCATION_ID
    ,SUM(V.FINANCIAL_COST_PLUS_PHYSICAL_COST_TOTAL) AS INV_VALUE
    ,SUM(V.QTY_AVAILABLE_PHYSICAL+v.QTY_PICKED) AS INV_PHYS
    ,V.DATA_AREA_ID
    ,V.[PARTITION]

FROM AXManagement.DBO.REX_INVENTORY_ON_HAND_V V 

WHERE  

    1=1
    AND V.DATA_AREA_ID          = @param_dataareaid
    AND V.WMS_LOCATION_ID       <> ''

GROUP BY 

    V.ITEM_ID
    ,V.CONFIG_ID
    ,v.INVENT_STYLE_ID
    ,V.INVENT_LOCATION_ID
    ,V.DATA_AREA_ID
    ,V.[PARTITION]
),
/*
CTE_INVENT_COST
DEFINITION: GATHERS INVENTORY VALUE AND CALCULATES AVERAGE 
[MAY BE UNNECESSARY THOUGH]
*/
CTE_INVENT_AVG AS (

    SELECT 

        t.ITEM_ID
        ,t.CONFIG_ID
        ,t.INVENT_STYLE_ID
        ,t.INVENT_LOCATION_ID
        ,t.INV_VALUE
        ,t.INV_PHYS
        ,iif(t.INV_PHYS <> 0, t.inv_value / t.inv_phys,0) as avg_cost
        ,T.DATA_AREA_ID
        ,T.[PARTITION]

    FROM CTE_INVENT_COST T 

)

SELECT 

    T.ITEMID
    ,V.ITEM_GROUP_ID
    ,V.ITEM_NAME
    ,T.CONFIG_ID
    ,t.INVENT_STYLE_ID
    ,t.INVENT_LOCATION_ID
    ,T.WMS_LOCATION_ID
    ,T.QTY as ONHANDQTY
    ,(T.QTY * INV.AVG_COST) AS ONHANDVALUE
    ,INV.INV_VALUE
    ,INV.avg_cost
    ,T.P1QTY
    ,T.BALANCE_QTY_P1
    ,T.P1_AGED_QTY
    ,(T.P1_AGED_QTY*INV.AVG_COST) AS P1_TOTAL
    ,T.P2QTY
    ,T.BALANCE_QTY_P2
    ,T.P2_AGED_QTY
    ,(T.P2_AGED_QTY*INV.AVG_COST) AS P2_TOTAL
    ,T.P3_AGED_QTY
    ,T.P3QTY
    ,T.BALANCE_QTY_P3
    ,(T.P3_AGED_QTY*INV.AVG_COST) AS P3_TOTAL
    ,T.P4_AGED_QTY
    ,T.P4QTY
    ,T.BALANCE_QTY_P4
    ,(T.P4_AGED_QTY*INV.AVG_COST) AS P4_TOTAL
    ,T.P5_AGED_QTY
    ,T.P5QTY
    ,T.BALANCE_QTY_P5
    ,(T.P5_AGED_QTY*INV.AVG_COST) AS P5_TOTAL

FROM CTE_P5 T 

LEFT JOIN CTE_INVENT_AVG INV 

    ON INV.ITEM_ID              = T.ITEMID
    AND INV.CONFIG_ID           = T.CONFIG_ID
    and INV.INVENT_STYLE_ID     = T.INVENT_STYLE_ID
    AND INV.INVENT_LOCATION_ID  = T.INVENT_LOCATION_ID
    AND INV.DATA_AREA_ID        = T.DATAAREAID
    AND INV.[PARTITION]         = T.[PARTITION]

LEFT JOIN AXManagement.DBO.REX_INVENT_TABLE_V V   

    ON V.ITEM_ID                = T.ITEMID
    AND V.DATA_AREA_ID          = T.DATAAREAID
    AND V.[PARTITION]           = T.[PARTITION]

ORDER BY 

    T.ITEMID ASC