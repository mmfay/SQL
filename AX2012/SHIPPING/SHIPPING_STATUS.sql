--------------------------------------------------------------------------------------------------------------
/*
Title: Shipping Status
Description: Provides Status on All Items Within a Specified Activity.
Parameters:
    Description: Parameters can be copied and pasted outside of comments for SQL Testing
    --(Required)
    DECLARE @param_activity VARCHAR(20) = 'C064147'
    ;
    --(Optional)
    --NONE
*/
--------------------------------------------------------------------------------------------------------------

/*
CTE_NOT_SHIPPED
Description: Gathers all of the items for a certain activity that are in the shipping screen but have not yet been shipped.
*/
WITH CTE_NOT_SHIPPED AS (

SELECT

    T.SHIPMENTID
    ,T.AXPSALESID
    ,T.SHIPPINGDATETIME
    ,T.INVENTLOCATIONID
    ,'Yes'                                                                      AS CURRENTACT
    ,T.AXPACTIVITYNUMBER
    ,T.DATAAREAID 
    ,T.[PARTITION]

FROM MicrosoftDynamicsAX.dbo.WMSSHIPMENT T 

WHERE 

    1=1
    AND T.AXPACTIVITYNUMBER             = @param_activity
    AND T.DATAAREAID                    = 'CI'
    AND T.SHIPPINGDATETIME              = '1900-01-01'

), 

/*
CTE_SHIPPED
Description: Gathers all of the items for a certain activity that are in the shipping screen and have not yet been shipped.
*/
CTE_SHIPPED AS (

SELECT

    T.SHIPMENTID
    ,T.AXPSALESID
    ,T.SHIPPINGDATETIME
    ,T.INVENTLOCATIONID
    ,'Yes'                                                                      AS CURRENTACT
    ,T.AXPACTIVITYNUMBER
    ,T.DATAAREAID 
    ,T.[PARTITION]

FROM MICROSOFTDYNAMICSAX.DBO.WMSSHIPMENT T 

WHERE 
    
    1=1
    AND T.AXPACTIVITYNUMBER                                                     = @param_activity
    AND T.DATAAREAID                                                            = 'CI'
    AND T.SHIPPINGDATETIME                                                      > '1900-01-01'

), 

/*
CTE_SUMMARY
Description: Gathers All of the Items From CTE_SHIPPED & CTE_NOT_SHIPPED, UNION with SALES ORDER OPEN Lines.
*/
CTE_SUMMARY AS (

SELECT 

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,V2.ITEM_NAME
    ,T.QTY
    ,T.SHIPMENTID
    ,T2.AXPSALESID
    ,T2.SHIPPINGDATETIME
    ,T2.AXPACTIVITYNUMBER
    ,IIF(T.EXPEDITIONSTATUS = 8,'Staged',IIF(T.EXPEDITIONSTATUS = 20,'Canceled','Review'))      AS HANDLING_STATUS
    ,'Not Shipped'                                                                              AS SHIPPING_STATUS
    ,T.INVENTDIMID
    ,T.DATAAREAID
    ,T.[PARTITION]
    ,V.INVENT_LOCATION_ID

FROM MICROSOFTDYNAMICSAX.DBO.WMSORDERTRANS T 

LEFT JOIN CTE_NOT_SHIPPED T2

    ON T2.SHIPMENTID = T.SHIPMENTID
    AND T2.DATAAREAID   = T.DATAAREAID
    AND T2.[PARTITION]  = T.[PARTITION]  

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID  = T.INVENTDIMID
    AND V.DATA_AREA_ID  = T.DATAAREAID
    AND V.[PARTITION]   = T.[PARTITION]

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_TABLE_V V2 

    ON V2.ITEM_ID       = T.ITEMID
    AND V2.DATA_AREA_ID = T.DATAAREAID
    AND V2.[PARTITION]  = T.[PARTITION]

WHERE 

    1=1
    AND T2.CURRENTACT = 'Yes'
	AND T.EXPEDITIONSTATUS = 8
        -- 8 (Filters outs Waiting Covered by kit req)

UNION 

SELECT 

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,V2.ITEM_NAME
    ,T.QTY
    ,T.SHIPMENTID
    ,T2.AXPSALESID
    ,T2.SHIPPINGDATETIME
    ,T2.AXPACTIVITYNUMBER
    ,IIF(T.EXPEDITIONSTATUS = 10, 'Complete','Review')      AS HANDLING_STATUS
    ,'Shipped'                                              AS SHIPPING_STATUS
    ,T.INVENTDIMID
    ,T.DATAAREAID
    ,T.[PARTITION]
    ,V.INVENT_LOCATION_ID

FROM MICROSOFTDYNAMICSAX.DBO.WMSORDERTRANS T 

LEFT JOIN CTE_SHIPPED T2

    ON T2.SHIPMENTID = T.SHIPMENTID
    AND T2.DATAAREAID   = T.DATAAREAID
    AND T2.[PARTITION]  = T.[PARTITION]  

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID  = T.INVENTDIMID
    AND V.DATA_AREA_ID  = T.DATAAREAID
    AND V.[PARTITION]   = T.[PARTITION]

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_TABLE_V V2 

    ON V2.ITEM_ID       = T.ITEMID
    AND V2.DATA_AREA_ID = T.DATAAREAID
    AND V2.[PARTITION]  = T.[PARTITION]

WHERE 

    1=1
    AND T2.CURRENTACT = 'Yes'
    AND T.EXPEDITIONSTATUS <> 20

UNION 

SELECT 

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,V2.ITEM_NAME
    ,T.REMAININVENTPHYSICAL
    ,'' AS SHIPMENTID
    ,T.SALESID
    ,'' AS SHIPPINGDATETIME
    ,T.ACTIVITYNUMBER
    ,'' AS HANDLING_STATUS
    ,'Not Shipped' AS SHIPPING_STATUS
    ,T.INVENTDIMID
    ,T.DATAAREAID
    ,T.[PARTITION]
    ,V.INVENT_LOCATION_ID

FROM MICROSOFTDYNAMICSAX.DBO.SALESLINE T 

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID              = T.INVENTDIMID
    AND V.DATA_AREA_ID              = T.DATAAREAID  
    AND V.[PARTITION]               = T.[PARTITION]

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_TABLE_V V2 

    ON V2.ITEM_ID                   = T.ITEMID
    AND V2.DATA_AREA_ID             = T.DATAAREAID
    AND V2.[PARTITION]              = T.[PARTITION]


WHERE 

    1=1 
    AND T.DATAAREAID                    = 'CI'
    AND T.ACTIVITYNUMBER                = @param_activity
    AND T.SALESSTATUS                   = 1
    AND T.QTYORDERED                    > 0

), 
/*
SUM_SALES_LINE
Description: Summarizes Sales Line for Activity.
*/
SUM_SALES_LINE AS (

SELECT 

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,V.INVENT_LOCATION_ID
    ,SUM(T.QTYORDERED) AS QTY_ORDERED
    ,T.SALESID
    ,T.DATAAREAID
    ,T.[PARTITION]
    ,MIN(T.CREATEDDATETIME) AS CREATED_TIME

FROM MICROSOFTDYNAMICSAX.DBO.SALESLINE T 

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID              = T.INVENTDIMID
    AND V.DATA_AREA_ID              = T.DATAAREAID  
    AND V.[PARTITION]               = T.[PARTITION]

WHERE 

    1=1 
    AND T.DATAAREAID = 'CI'
    AND T.ACTIVITYNUMBER = @param_activity
    
GROUP BY

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,T.SALESID
    ,T.DATAAREAID
    ,T.[PARTITION]
    ,V.INVENT_LOCATION_ID

), 

/*
NET_REQ
Description: Gets location of item in Net Requirements. Shows if on Schedule or Not.
*/
NET_REQ AS (

SELECT

    T.ITEMID
    ,V.CONFIG_ID
    ,V.INVENT_STYLE_ID
    ,T.REFID
    ,T.QTY
    ,T4.ACTIVITYNUMBER
    ,SUM(T.QTY) OVER (PARTITION BY T.ITEMID, V.CONFIG_ID, V.INVENT_STYLE_ID, V.INVENT_LOCATION_ID ORDER BY T.REQDATE, T.REFID, T.RECID) AS ACCUMULATED
    ,T.REQDATE
    ,T.DATAAREAID
    ,V.INVENT_LOCATION_ID
    ,T2.REQPLANID
    ,T.RECID
    ,T.[PARTITION]

FROM MICROSOFTDYNAMICSAX.DBO.REQTRANS T 

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_DIM_V V 

    ON V.INVENT_DIM_ID          	= T.COVINVENTDIMID
    AND V.DATA_AREA_ID          	= T.DATAAREAID
    AND V.[PARTITION]           		= T.[PARTITION]

LEFT JOIN MICROSOFTDYNAMICSAX.DBO.REQPLANVERSION T2

    ON T2.RECID                 		= T.PLANVERSION
    AND T2.REQPLANDATAAREAID    	= T.DATAAREAID
    AND T2.[PARTITION]          	= T.[PARTITION]

LEFT JOIN MICROSOFTDYNAMICSAX.DBO.INVENTTRANSORIGIN T3 

    ON T3.RECID         = T.INVENTTRANSORIGIN
    AND T3.DATAAREAID   = T.DATAAREAID
    AND T3.[PARTITION]  = T.[PARTITION]

LEFT JOIN MICROSOFTDYNAMICSAX.DBO.SALESLINE T4

    ON T4.INVENTTRANSID         = T3.INVENTTRANSID
    AND T4.DATAAREAID           = T3.DATAAREAID
    AND T4.[PARTITION]          = T3.[PARTITION]

WHERE 

    1=1
    AND T.ITEMID IN (

        SELECT 

            T.ITEMID

        FROM MICROSOFTDYNAMICSAX.DBO.SALESLINE T 

        WHERE 

            1=1
            AND T.SALESSTATUS = 1
            AND T.ACTIVITYNUMBER = @param_activity
    )
    AND T.REFTYPE <> 14
    AND T2.REQPLANID = 'Current'
    AND T.DATAAREAID = 'CI'


)

SELECT 

    T.ITEMID
    ,T.CONFIG_ID
    ,T.INVENT_STYLE_ID
    ,T.ITEM_NAME
    ,T.QTY
    ,T.SHIPMENTID
    ,T.AXPSALESID
    ,T.SHIPPINGDATETIME
    ,T.AXPACTIVITYNUMBER
    ,T.Handling_Status
    ,T.shipping_status
    ,T2.created_time
    ,T.INVENT_LOCATION_ID
    ,NR.ACCUMULATED
    ,NR.RECID                                                               --2020/12/28 Add - MF
    ,COUNT(OA1.ISSUERECID)                      AS SUPPLY_PEGS              --2020/12/28 Add - MF
    ,OA2.RECEIPTRECID                           AS PEGGED_RECID             --2020/12/28 Add - MF
    ,OA3.REFID                                  AS SUPPLY_REF_ID            --2020/12/28 Add - MF
    ,OA3.REFTYPE                                AS SUPPLY_REF_TYPE          --2020/12/28 Add - MF
    ,CONVERT(DATE,OA4.CONFIRMEDDLV)             AS CDD                      --2020/12/28 Add - MF

FROM CTE_SUMMARY T 

LEFT JOIN SUM_SALES_LINE T2 

    ON T2.ITEMID                    			= T.ITEMID
    AND T2.CONFIG_ID                		= T.CONFIG_ID
    AND T2.INVENT_STYLE_ID          		= T.INVENT_STYLE_ID
    AND T2.DATAAREAID               		= T.DATAAREAID
    AND T2.SALESID                  			= T.AXPSALESID
    AND T2.[PARTITION]              		= T.[PARTITION]
    AND T2.INVENT_LOCATION_ID       		= T.INVENT_LOCATION_ID

LEFT JOIN NET_REQ NR 

    ON NR.ITEMID                    			= T.ITEMID
    AND NR.CONFIG_ID                		= T.CONFIG_ID
    AND NR.INVENT_STYLE_ID          		= T.INVENT_STYLE_ID
    AND NR.INVENT_LOCATION_ID       		= T.INVENT_LOCATION_ID
    AND NR.REFID                    		= T.AXPSALESID
    AND NR.ACTIVITYNUMBER           		= T.AXPACTIVITYNUMBER
    AND NR.[PARTITION]              		= T.[PARTITION]
    AND NR.DATAAREAID               		= T.DATAAREAID
    AND ABS(NR.QTY)                 		= T.QTY

/*
OUTER APPLY
Description: Link Pegging to Sales Lines for Easy Visibility by Activity Rather Than by Item.
*/
OUTER APPLY (

SELECT

*

FROM MICROSOFTDYNAMICSAX.DBO.REQTRANSCOV C 

WHERE 

    1=1
    AND C.ISSUERECID            = NR.RECID
    AND C.DATAAREAID            = T.DATAAREAID
    AND C.[PARTITION]           = T.[PARTITION]

) OA1 --2020/12/28 ADD - MF

OUTER APPLY ( 

SELECT TOP 1

*

FROM MICROSOFTDYNAMICSAX.DBO.REQTRANSCOV C 

WHERE 

    1=1
    AND C.ISSUERECID          = NR.RECID
    AND C.DATAAREAID            = T.DATAAREAID
    AND C.[PARTITION]           = T.[PARTITION]

) OA2 --2020/12/28 ADD - MF

OUTER APPLY ( 

SELECT TOP 1 

* 

FROM MICROSOFTDYNAMICSAX.DBO.REQTRANS C  

WHERE 

    1=1
    AND C.RECID                 = OA2.RECEIPTRECID
    AND C.DATAAREAID            = T.DATAAREAID
    AND C.[PARTITION]           = T.[PARTITION]

) OA3 --2020/12/28 ADD - MF

OUTER APPLY ( 

SELECT 

    C.CONFIRMEDDLV

FROM MICROSOFTDYNAMICSAX.DBO.PURCHLINE C 

LEFT JOIN AXMANAGEMENT.DBO.REX_INVENT_DIM_V C1 

    ON C.INVENTDIMID          = C1.INVENT_DIM_ID 
    AND C.DATAAREAID          = C1.DATA_AREA_ID
    AND C.[PARTITION]         = C1.[PARTITION]

WHERE 

    1=1
    AND T.ITEMID                    = C.ITEMID
    AND T.CONFIG_ID                 = C1.CONFIG_ID
    AND T.INVENT_STYLE_ID           = C1.INVENT_STYLE_ID
    AND T.INVENT_LOCATION_ID        = C1.INVENT_LOCATION_ID
    AND OA3.REFID                   = C.PURCHID
    --AND T.QTY                       = C.REMAINPURCHPHYSICAL
    AND T.DATAAREAID                = C.DATAAREAID
    AND T.[PARTITION]               = C.[PARTITION]
    AND C.ISDELETED                 = 0

) OA4 --2020/12/28 ADD - MF


GROUP BY --2020/12/28 ADD - MF
    T.ITEMID
    ,T.CONFIG_ID
    ,T.INVENT_STYLE_ID
    ,T.ITEM_NAME
    ,T.QTY
    ,T.SHIPMENTID
    ,T.AXPSALESID
    ,T.SHIPPINGDATETIME
    ,T.AXPACTIVITYNUMBER
    ,T.HANDLING_STATUS
    ,T.SHIPPING_STATUS
    ,T2.CREATED_TIME
    ,T.INVENT_LOCATION_ID
    ,NR.ACCUMULATED
    ,NR.RECID
    ,OA2.RECEIPTRECID                           
    ,OA3.REFID                                  
    ,OA3.REFTYPE                                
    ,CONVERT(DATE,OA4.CONFIRMEDDLV)       
          
ORDER BY 
    T.SHIPPING_STATUS ASC
    ,T.HANDLING_STATUS ASC
    ,NR.ACCUMULATED ASC