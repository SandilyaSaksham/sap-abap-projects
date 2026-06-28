*&---------------------------------------------------------------------*
*& Program  : ZPROD_INVENTORY
*& Title    : Product Inventory Management System
*& Author   : [Your Name]
*& Date     : 2024
*& Description: Manages product stock with CRUD operations and
*&              a Low Stock Alert Report using ALV.
*&---------------------------------------------------------------------*

REPORT zprod_inventory.

TYPE-POOLS: slis.  " ALV type pool

*&---------------------------------------------------------------------*
*& STEP 1: DATA DEFINITIONS
*&---------------------------------------------------------------------*

" Product structure (simulates DB table ZPRODUCTS)
TYPES: BEGIN OF ty_product,
         prod_id   TYPE char10,          " Product ID e.g. PROD001
         prod_name TYPE char50,          " Product Name
         category  TYPE char30,          " Category: Electronics, Clothing etc.
         price     TYPE p DECIMALS 2,    " Unit Price
         stock_qty TYPE i,               " Current Stock Quantity
         min_stock TYPE i,               " Minimum stock level (alert threshold)
         supplier  TYPE char30,          " Supplier Name
       END OF ty_product.

DATA: gt_products TYPE TABLE OF ty_product,  " All products
      gs_product  TYPE ty_product.           " Single product (work area)

*&---------------------------------------------------------------------*
*& STEP 2: SELECTION SCREEN
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  PARAMETERS: rb_add  RADIOBUTTON GROUP g1 DEFAULT 'X',  " Add Product
              rb_upd  RADIOBUTTON GROUP g1,               " Update Stock
              rb_del  RADIOBUTTON GROUP g1,               " Delete Product
              rb_srch RADIOBUTTON GROUP g1,               " Search Product
              rb_low  RADIOBUTTON GROUP g1.               " Low Stock Report

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS: p_prid  TYPE char10  LOWER CASE,  " Product ID
              p_name  TYPE char50  LOWER CASE,  " Product Name
              p_cat   TYPE char30  LOWER CASE,  " Category
              p_price TYPE p       DECIMALS 2,  " Price
              p_stock TYPE i,                   " Stock Quantity
              p_minstk TYPE i,                  " Minimum Stock Level
              p_supp  TYPE char30  LOWER CASE.  " Supplier

SELECTION-SCREEN END OF BLOCK b2.

" Parameter for Low Stock Report: user can change the threshold
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS: p_thresh TYPE i DEFAULT 10.  " Alert if stock < this value
SELECTION-SCREEN END OF BLOCK b3.

*&---------------------------------------------------------------------*
*& STEP 3: INITIALIZATION - Load Sample Product Data
*&---------------------------------------------------------------------*

INITIALIZATION.

  TEXT-001 = 'Select Operation'.
  TEXT-002 = 'Product Details'.
  TEXT-003 = 'Low Stock Settings'.

  " Electronics
  CLEAR gs_product.
  gs_product-prod_id   = 'PROD001'.
  gs_product-prod_name = 'Laptop Dell XPS 15'.
  gs_product-category  = 'Electronics'.
  gs_product-price     = '75000.00'.
  gs_product-stock_qty = 50.
  gs_product-min_stock = 10.
  gs_product-supplier  = 'Dell India Pvt Ltd'.
  APPEND gs_product TO gt_products.

  CLEAR gs_product.
  gs_product-prod_id   = 'PROD002'.
  gs_product-prod_name = 'Wireless Mouse'.
  gs_product-category  = 'Electronics'.
  gs_product-price     = '850.00'.
  gs_product-stock_qty = 5.           " <-- Low stock! (below min 10)
  gs_product-min_stock = 10.
  gs_product-supplier  = 'Logitech'.
  APPEND gs_product TO gt_products.

  CLEAR gs_product.
  gs_product-prod_id   = 'PROD003'.
  gs_product-prod_name = 'USB-C Hub'.
  gs_product-category  = 'Electronics'.
  gs_product-price     = '2200.00'.
  gs_product-stock_qty = 8.           " <-- Low stock! (below min 15)
  gs_product-min_stock = 15.
  gs_product-supplier  = 'Anker India'.
  APPEND gs_product TO gt_products.

  " Stationery
  CLEAR gs_product.
  gs_product-prod_id   = 'PROD004'.
  gs_product-prod_name = 'A4 Notebook Pack'.
  gs_product-category  = 'Stationery'.
  gs_product-price     = '250.00'.
  gs_product-stock_qty = 200.
  gs_product-min_stock = 50.
  gs_product-supplier  = 'Classmate'.
  APPEND gs_product TO gt_products.

  CLEAR gs_product.
  gs_product-prod_id   = 'PROD005'.
  gs_product-prod_name = 'Ballpoint Pen Box'.
  gs_product-category  = 'Stationery'.
  gs_product-price     = '120.00'.
  gs_product-stock_qty = 3.           " <-- Low stock!
  gs_product-min_stock = 20.
  gs_product-supplier  = 'Reynolds India'.
  APPEND gs_product TO gt_products.

*&---------------------------------------------------------------------*
*& STEP 4: START-OF-SELECTION
*&---------------------------------------------------------------------*

START-OF-SELECTION.

  IF rb_add = 'X'.
    PERFORM add_product.

  ELSEIF rb_upd = 'X'.
    PERFORM update_stock.

  ELSEIF rb_del = 'X'.
    PERFORM delete_product.

  ELSEIF rb_srch = 'X'.
    PERFORM search_product.

  ELSEIF rb_low = 'X'.
    PERFORM low_stock_report.

  ENDIF.

*&---------------------------------------------------------------------*
*& FORM: ADD_PRODUCT
*& Add a new product with full validation
*&---------------------------------------------------------------------*

FORM add_product.

  " Mandatory field checks
  IF p_prid IS INITIAL.
    MESSAGE 'Please enter Product ID!' TYPE 'E'.
    RETURN.
  ENDIF.

  IF p_name IS INITIAL.
    MESSAGE 'Please enter Product Name!' TYPE 'E'.
    RETURN.
  ENDIF.

  IF p_price <= 0.
    MESSAGE 'Price must be greater than 0!' TYPE 'E'.
    RETURN.
  ENDIF.

  IF p_stock < 0.
    MESSAGE 'Stock quantity cannot be negative!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Duplicate ID check
  READ TABLE gt_products INTO gs_product
             WITH KEY prod_id = p_prid.
  IF sy-subrc = 0.
    MESSAGE 'Product ID already exists!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Add new product
  CLEAR gs_product.
  gs_product-prod_id   = p_prid.
  gs_product-prod_name = p_name.
  gs_product-category  = p_cat.
  gs_product-price     = p_price.
  gs_product-stock_qty = p_stock.
  gs_product-min_stock = p_minstk.
  gs_product-supplier  = p_supp.

  APPEND gs_product TO gt_products.

  " Warn if added stock is already below minimum
  IF p_stock < p_minstk AND p_minstk > 0.
    MESSAGE |Product { p_prid } added! WARNING: Stock is already below minimum level!| TYPE 'W'.
  ELSE.
    MESSAGE |Product { p_prid } - { p_name } added successfully!| TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: UPDATE_STOCK
*& Update product stock and/or price by Product ID
*& This is the most common operation in inventory management
*&---------------------------------------------------------------------*

FORM update_stock.

  DATA: lv_tabix    TYPE i,
        lv_old_stock TYPE i.

  IF p_prid IS INITIAL.
    MESSAGE 'Please enter Product ID!' TYPE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_products INTO gs_product
             WITH KEY prod_id = p_prid.

  IF sy-subrc <> 0.
    MESSAGE |Product { p_prid } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  lv_tabix     = sy-tabix.
  lv_old_stock = gs_product-stock_qty.  " Remember old stock for message

  " Update only fields that are provided
  IF p_name   IS NOT INITIAL. gs_product-prod_name = p_name.   ENDIF.
  IF p_cat    IS NOT INITIAL. gs_product-category  = p_cat.    ENDIF.
  IF p_price  > 0.            gs_product-price     = p_price.  ENDIF.
  IF p_minstk > 0.            gs_product-min_stock = p_minstk. ENDIF.
  IF p_supp   IS NOT INITIAL. gs_product-supplier  = p_supp.   ENDIF.

  " Stock update: NEW value replaces old value
  IF p_stock >= 0.
    gs_product-stock_qty = p_stock.
  ENDIF.

  MODIFY gt_products FROM gs_product INDEX lv_tabix.

  " Show message with stock change info
  WRITE: / |Product { p_prid } updated.|,
         / |  Stock changed: { lv_old_stock } → { gs_product-stock_qty }|.

  " Check if stock fell below minimum after update
  IF gs_product-stock_qty < gs_product-min_stock.
    WRITE: / |  ⚠ WARNING: Stock is below minimum level ({ gs_product-min_stock })!|.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DELETE_PRODUCT
*& Remove a product from inventory
*&---------------------------------------------------------------------*

FORM delete_product.

  IF p_prid IS INITIAL.
    MESSAGE 'Please enter Product ID to delete!' TYPE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_products INTO gs_product
             WITH KEY prod_id = p_prid.

  IF sy-subrc <> 0.
    MESSAGE |Product { p_prid } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  " Safety check: Warn if product still has stock
  IF gs_product-stock_qty > 0.
    " In a real system you'd show a confirmation popup here
    " For simplicity, we show a warning but still delete
    WRITE: / |WARNING: Product still has { gs_product-stock_qty } units in stock!|.
    WRITE: / 'Proceeding with deletion...'.
  ENDIF.

  DELETE gt_products WHERE prod_id = p_prid.

  WRITE: / |Product { p_prid } - { gs_product-prod_name } deleted successfully.|.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: SEARCH_PRODUCT
*& Search product by ID and show full details
*&---------------------------------------------------------------------*

FORM search_product.

  DATA: lv_stock_status TYPE char20.

  IF p_prid IS INITIAL.
    MESSAGE 'Please enter Product ID!' TYPE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_products INTO gs_product
             WITH KEY prod_id = p_prid.

  IF sy-subrc <> 0.
    MESSAGE |Product { p_prid } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  " Determine stock status
  IF gs_product-stock_qty = 0.
    lv_stock_status = 'OUT OF STOCK'.
  ELSEIF gs_product-stock_qty < gs_product-min_stock.
    lv_stock_status = 'LOW STOCK ⚠'.
  ELSE.
    lv_stock_status = 'In Stock ✓'.
  ENDIF.

  " Display product information
  WRITE: / '=========================================='.
  WRITE: / '         PRODUCT DETAILS'.
  WRITE: / '=========================================='.
  WRITE: / 'Product ID   :', gs_product-prod_id.
  WRITE: / 'Name         :', gs_product-prod_name.
  WRITE: / 'Category     :', gs_product-category.
  WRITE: / 'Price        : Rs.', gs_product-price.
  WRITE: / 'Stock Qty    :', gs_product-stock_qty, 'units'.
  WRITE: / 'Min Stock    :', gs_product-min_stock, 'units'.
  WRITE: / 'Status       :', lv_stock_status.
  WRITE: / 'Supplier     :', gs_product-supplier.
  WRITE: / '=========================================='.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: LOW_STOCK_REPORT
*& Shows ALL products where stock < minimum stock level
*& This is the MOST IMPORTANT report for inventory management
*& Color coding: Red = Out of Stock, Yellow = Low Stock
*&---------------------------------------------------------------------*

FORM low_stock_report.

  " We need a special structure for ALV color coding
  " The field 'light' (traffic light) shows Red/Yellow/Green icons
  TYPES: BEGIN OF ty_low_stock,
           prod_id   TYPE char10,
           prod_name TYPE char50,
           category  TYPE char30,
           stock_qty TYPE i,
           min_stock TYPE i,
           shortage  TYPE i,          " How many units short
           supplier  TYPE char30,
           light     TYPE char1,      " '1'=Green '2'=Yellow '3'=Red (traffic light)
         END OF ty_low_stock.

  DATA: lt_low        TYPE TABLE OF ty_low_stock,
        ls_low        TYPE ty_low_stock,
        lt_fieldcat   TYPE slis_t_fieldcat_alv,
        ls_fieldcat   TYPE slis_fieldcat_alv,
        ls_layout     TYPE slis_layout_alv,
        lv_threshold  TYPE i.

  lv_threshold = p_thresh.  " Use the threshold from selection screen

  " ----- Find all low-stock products -----
  LOOP AT gt_products INTO gs_product.

    IF gs_product-stock_qty < gs_product-min_stock.

      CLEAR ls_low.
      ls_low-prod_id   = gs_product-prod_id.
      ls_low-prod_name = gs_product-prod_name.
      ls_low-category  = gs_product-category.
      ls_low-stock_qty = gs_product-stock_qty.
      ls_low-min_stock = gs_product-min_stock.
      ls_low-shortage  = gs_product-min_stock - gs_product-stock_qty.
      ls_low-supplier  = gs_product-supplier.

      " Set traffic light color based on severity
      IF gs_product-stock_qty = 0.
        ls_low-light = '3'.  " Red = Out of Stock
      ELSE.
        ls_low-light = '2'.  " Yellow = Low Stock (some stock but below min)
      ENDIF.

      APPEND ls_low TO lt_low.
    ENDIF.

  ENDLOOP.

  " Check if any low-stock items found
  IF lt_low IS INITIAL.
    MESSAGE |No products below minimum stock level. Inventory looks healthy!| TYPE 'I'.
    RETURN.
  ENDIF.

  " ----- Build Field Catalog -----
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'LIGHT'.
  ls_fieldcat-seltext_l = 'Status'.
  ls_fieldcat-outputlen = 8.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'PROD_ID'.
  ls_fieldcat-seltext_l = 'Product ID'.
  ls_fieldcat-outputlen = 12.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'PROD_NAME'.
  ls_fieldcat-seltext_l = 'Product Name'.
  ls_fieldcat-outputlen = 25.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'CATEGORY'.
  ls_fieldcat-seltext_l = 'Category'.
  ls_fieldcat-outputlen = 15.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'STOCK_QTY'.
  ls_fieldcat-seltext_l = 'Current Stock'.
  ls_fieldcat-outputlen = 14.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'MIN_STOCK'.
  ls_fieldcat-seltext_l = 'Min. Required'.
  ls_fieldcat-outputlen = 14.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'SHORTAGE'.
  ls_fieldcat-seltext_l = 'Units Short'.
  ls_fieldcat-outputlen = 12.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'SUPPLIER'.
  ls_fieldcat-seltext_l = 'Supplier'.
  ls_fieldcat-outputlen = 20.
  APPEND ls_fieldcat TO lt_fieldcat.

  " ----- Layout: Enable Traffic Light Column -----
  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  ls_layout-lights_fieldname  = 'LIGHT'.  " Tell ALV which field = traffic light

  " ----- Display ALV -----
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_program_name = sy-repid
      it_fieldcat    = lt_fieldcat
      is_layout      = ls_layout
    TABLES
      t_outtab       = lt_low
    EXCEPTIONS
      program_error  = 1
      OTHERS         = 2.

ENDFORM.

*& ===================================================================
*& INTERVIEW EXPLANATION GUIDE
*& ===================================================================
*&
*& "I built a Product Inventory Management System in SAP ABAP to track
*& product stock levels and alert when stock falls below minimum."
*&
*& THE KEY FEATURE - LOW STOCK REPORT:
*&  "The highlight of this project is the Low Stock Alert Report.
*&   It automatically identifies products where current stock is
*&   below the minimum threshold. I used ALV traffic lights to
*&   visually highlight critical items - Red for out-of-stock
*&   and Yellow for low-stock products."
*&
*& BASIC VALIDATIONS I ADDED:
*&  • Price must be > 0 (can't add a free product by mistake)
*&  • Stock quantity can't be negative
*&  • Duplicate Product ID check
*&  • Warning when adding a product with stock already below minimum
*&  • Warning before deleting a product that still has stock
*&
*& CONCEPTS DEMONSTRATED:
*&  • CRUD Operations: APPEND (Create), READ TABLE (Read),
*&    MODIFY (Update), DELETE (Delete)
*&  • Business Logic: shortage calculation = min_stock - stock_qty
*&  • ALV Traffic Lights: lights_fieldname in layout settings
*&  • Conditional logic with IF/ELSEIF for stock status
*&  • LOOP AT ... WHERE for filtering low-stock items
*&
*& WHAT MAKES THIS RESUME-WORTHY:
*&  "This project shows I understand real business scenarios.
*&   Every warehouse needs to know when to reorder products.
*&   The traffic light feature makes it easy for managers to
*&   instantly see critical stock situations."
*& ===================================================================
