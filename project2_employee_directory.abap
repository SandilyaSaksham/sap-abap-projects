*&---------------------------------------------------------------------*
*& Program  : ZEMP_DIRECTORY
*& Title    : Employee Directory System
*& Author   : [Your Name]
*& Date     : 2024
*& Description: Manages employee records with department-wise reports
*&              and salary reports using ALV.
*&---------------------------------------------------------------------*

REPORT zemp_directory.

TYPE-POOLS: slis.  " Required for ALV

*&---------------------------------------------------------------------*
*& STEP 1: DEFINE STRUCTURES AND INTERNAL TABLES
*&---------------------------------------------------------------------*

" Main Employee structure (simulates custom DB table ZEMPLOYEES)
TYPES: BEGIN OF ty_employee,
         emp_id   TYPE char8,      " Employee ID e.g. EMP00001
         emp_name TYPE char50,     " Full Name
         dept     TYPE char30,     " Department: IT, HR, Finance, etc.
         desig    TYPE char30,     " Designation: Manager, Analyst, etc.
         salary   TYPE p DECIMALS 2, " Monthly Salary
         phone    TYPE char15,     " Contact Number
         city     TYPE char30,     " City
       END OF ty_employee.

" Structure for Salary Report (department-wise summary)
TYPES: BEGIN OF ty_salary_rpt,
         dept       TYPE char30,   " Department Name
         emp_count  TYPE i,        " Number of Employees
         total_sal  TYPE p DECIMALS 2, " Total Salary of dept
         avg_sal    TYPE p DECIMALS 2, " Average Salary
         max_sal    TYPE p DECIMALS 2, " Highest Salary
       END OF ty_salary_rpt.

" Global internal tables
DATA: gt_employees  TYPE TABLE OF ty_employee,    " All employees
      gs_employee   TYPE ty_employee,             " Single employee
      gt_salary_rpt TYPE TABLE OF ty_salary_rpt,  " Salary report data
      gs_salary_rpt TYPE ty_salary_rpt.

*&---------------------------------------------------------------------*
*& STEP 2: SELECTION SCREEN
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  PARAMETERS: rb_add  RADIOBUTTON GROUP g1 DEFAULT 'X',  " Add Employee
              rb_srch RADIOBUTTON GROUP g1,               " Search by ID
              rb_upd  RADIOBUTTON GROUP g1,               " Update Details
              rb_dept RADIOBUTTON GROUP g1,               " Dept-wise List
              rb_sal  RADIOBUTTON GROUP g1.               " Salary Report

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS: p_empid  TYPE char8   LOWER CASE,  " Employee ID
              p_name   TYPE char50  LOWER CASE,  " Name
              p_dept   TYPE char30  LOWER CASE,  " Department
              p_desig  TYPE char30  LOWER CASE,  " Designation
              p_sal    TYPE p       DECIMALS 2,  " Salary
              p_phone  TYPE char15  LOWER CASE,  " Phone
              p_city   TYPE char30  LOWER CASE.  " City

SELECTION-SCREEN END OF BLOCK b2.

" Separate parameter to filter by department in the dept-wise list
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS: p_filter TYPE char30 LOWER CASE.  " Filter by Dept (optional)
SELECTION-SCREEN END OF BLOCK b3.

*&---------------------------------------------------------------------*
*& STEP 3: INITIALIZATION - Load Sample Employee Data
*&---------------------------------------------------------------------*

INITIALIZATION.

  TEXT-001 = 'Select Operation'.
  TEXT-002 = 'Employee Details'.
  TEXT-003 = 'Filter (Optional)'.

  " Sample data: IT Department
  CLEAR gs_employee.
  gs_employee-emp_id   = 'EMP00001'.
  gs_employee-emp_name = 'Vikram Nair'.
  gs_employee-dept     = 'IT'.
  gs_employee-desig    = 'Senior Developer'.
  gs_employee-salary   = '75000'.
  gs_employee-phone    = '9876543210'.
  gs_employee-city     = 'Bangalore'.
  APPEND gs_employee TO gt_employees.

  CLEAR gs_employee.
  gs_employee-emp_id   = 'EMP00002'.
  gs_employee-emp_name = 'Sneha Patil'.
  gs_employee-dept     = 'IT'.
  gs_employee-desig    = 'SAP Consultant'.
  gs_employee-salary   = '65000'.
  gs_employee-phone    = '9876543211'.
  gs_employee-city     = 'Pune'.
  APPEND gs_employee TO gt_employees.

  " Sample data: HR Department
  CLEAR gs_employee.
  gs_employee-emp_id   = 'EMP00003'.
  gs_employee-emp_name = 'Anjali Mehta'.
  gs_employee-dept     = 'HR'.
  gs_employee-desig    = 'HR Manager'.
  gs_employee-salary   = '60000'.
  gs_employee-phone    = '9876543212'.
  gs_employee-city     = 'Mumbai'.
  APPEND gs_employee TO gt_employees.

  CLEAR gs_employee.
  gs_employee-emp_id   = 'EMP00004'.
  gs_employee-emp_name = 'Rohit Gupta'.
  gs_employee-dept     = 'HR'.
  gs_employee-desig    = 'HR Executive'.
  gs_employee-salary   = '35000'.
  gs_employee-phone    = '9876543213'.
  gs_employee-city     = 'Delhi'.
  APPEND gs_employee TO gt_employees.

  " Sample data: Finance Department
  CLEAR gs_employee.
  gs_employee-emp_id   = 'EMP00005'.
  gs_employee-emp_name = 'Deepak Joshi'.
  gs_employee-dept     = 'Finance'.
  gs_employee-desig    = 'Finance Manager'.
  gs_employee-salary   = '80000'.
  gs_employee-phone    = '9876543214'.
  gs_employee-city     = 'Hyderabad'.
  APPEND gs_employee TO gt_employees.

*&---------------------------------------------------------------------*
*& STEP 4: START-OF-SELECTION - Main Logic
*&---------------------------------------------------------------------*

START-OF-SELECTION.

  IF rb_add = 'X'.
    PERFORM add_employee.

  ELSEIF rb_srch = 'X'.
    PERFORM search_employee.

  ELSEIF rb_upd = 'X'.
    PERFORM update_employee.

  ELSEIF rb_dept = 'X'.
    PERFORM dept_wise_list.

  ELSEIF rb_sal = 'X'.
    PERFORM salary_report.

  ENDIF.

*&---------------------------------------------------------------------*
*& FORM: ADD_EMPLOYEE
*&---------------------------------------------------------------------*

FORM add_employee.

  " Validation
  IF p_empid IS INITIAL.
    MESSAGE 'Please enter Employee ID!' TYPE 'E'.
    RETURN.
  ENDIF.

  IF p_name IS INITIAL.
    MESSAGE 'Please enter Employee Name!' TYPE 'E'.
    RETURN.
  ENDIF.

  IF p_dept IS INITIAL.
    MESSAGE 'Please enter Department!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Check for duplicate Employee ID
  READ TABLE gt_employees INTO gs_employee
             WITH KEY emp_id = p_empid.
  IF sy-subrc = 0.
    MESSAGE 'Employee ID already exists!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Add the new employee
  CLEAR gs_employee.
  gs_employee-emp_id   = p_empid.
  gs_employee-emp_name = p_name.
  gs_employee-dept     = p_dept.
  gs_employee-desig    = p_desig.
  gs_employee-salary   = p_sal.
  gs_employee-phone    = p_phone.
  gs_employee-city     = p_city.

  APPEND gs_employee TO gt_employees.

  MESSAGE |Employee { p_empid } - { p_name } added successfully!| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: SEARCH_EMPLOYEE
*& Search by Employee ID and display full details
*&---------------------------------------------------------------------*

FORM search_employee.

  IF p_empid IS INITIAL.
    MESSAGE 'Please enter Employee ID!' TYPE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_employees INTO gs_employee
             WITH KEY emp_id = p_empid.

  IF sy-subrc <> 0.
    MESSAGE |Employee { p_empid } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  " Display employee details
  WRITE: / '========================================'.
  WRITE: / '        EMPLOYEE PROFILE'.
  WRITE: / '========================================'.
  WRITE: / 'Employee ID  :', gs_employee-emp_id.
  WRITE: / 'Name         :', gs_employee-emp_name.
  WRITE: / 'Department   :', gs_employee-dept.
  WRITE: / 'Designation  :', gs_employee-desig.
  WRITE: / 'Salary       : Rs.', gs_employee-salary.
  WRITE: / 'Phone        :', gs_employee-phone.
  WRITE: / 'City         :', gs_employee-city.
  WRITE: / '========================================'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: UPDATE_EMPLOYEE
*& Update employee details by Employee ID
*&---------------------------------------------------------------------*

FORM update_employee.

  DATA: lv_tabix TYPE i.

  IF p_empid IS INITIAL.
    MESSAGE 'Please enter Employee ID to update!' TYPE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_employees INTO gs_employee
             WITH KEY emp_id = p_empid.

  IF sy-subrc <> 0.
    MESSAGE |Employee { p_empid } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  lv_tabix = sy-tabix.  " Remember the row number

  " Update only the fields the user has filled in
  IF p_name  IS NOT INITIAL. gs_employee-emp_name = p_name.  ENDIF.
  IF p_dept  IS NOT INITIAL. gs_employee-dept     = p_dept.  ENDIF.
  IF p_desig IS NOT INITIAL. gs_employee-desig    = p_desig. ENDIF.
  IF p_sal   IS NOT INITIAL. gs_employee-salary   = p_sal.   ENDIF.
  IF p_phone IS NOT INITIAL. gs_employee-phone    = p_phone. ENDIF.
  IF p_city  IS NOT INITIAL. gs_employee-city     = p_city.  ENDIF.

  MODIFY gt_employees FROM gs_employee INDEX lv_tabix.

  MESSAGE |Employee { p_empid } updated successfully!| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DEPT_WISE_LIST
*& Shows employee list filtered by department (ALV Report)
*& If no filter given, shows ALL employees
*&---------------------------------------------------------------------*

FORM dept_wise_list.

  DATA: lt_fieldcat  TYPE slis_t_fieldcat_alv,
        ls_fieldcat  TYPE slis_fieldcat_alv,
        ls_layout    TYPE slis_layout_alv,
        ls_sort      TYPE slis_sortinfo_alv,   " For sorting
        lt_sort      TYPE slis_t_sortinfo_alv, " Sort table
        lt_display   TYPE TABLE OF ty_employee, " Data to display
        ls_display   TYPE ty_employee.

  " ----- Filter Data -----
  " If user entered a department filter, show only that dept
  " Otherwise show everyone
  IF p_filter IS NOT INITIAL.
    LOOP AT gt_employees INTO ls_display
         WHERE dept = p_filter.
      APPEND ls_display TO lt_display.
    ENDLOOP.

    IF lt_display IS INITIAL.
      MESSAGE |No employees found in department: { p_filter }| TYPE 'I'.
      RETURN.
    ENDIF.
  ELSE.
    lt_display = gt_employees.  " Show all employees
  ENDIF.

  " ----- Build Field Catalog (Columns) -----
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'EMP_ID'.
  ls_fieldcat-seltext_l = 'Emp ID'.
  ls_fieldcat-outputlen = 10.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'EMP_NAME'.
  ls_fieldcat-seltext_l = 'Employee Name'.
  ls_fieldcat-outputlen = 25.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'DEPT'.
  ls_fieldcat-seltext_l = 'Department'.
  ls_fieldcat-outputlen = 15.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'DESIG'.
  ls_fieldcat-seltext_l = 'Designation'.
  ls_fieldcat-outputlen = 20.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'SALARY'.
  ls_fieldcat-seltext_l = 'Salary (Rs.)'.
  ls_fieldcat-outputlen = 12.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'CITY'.
  ls_fieldcat-seltext_l = 'City'.
  ls_fieldcat-outputlen = 15.
  APPEND ls_fieldcat TO lt_fieldcat.

  " ----- Sort by Department -----
  CLEAR ls_sort.
  ls_sort-fieldname = 'DEPT'.
  ls_sort-up        = 'X'.   " Ascending order
  APPEND ls_sort TO lt_sort.

  " ----- Layout -----
  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  " ----- Display ALV -----
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_program_name = sy-repid
      it_fieldcat    = lt_fieldcat
      is_layout      = ls_layout
      it_sort        = lt_sort      " Pass sort settings
    TABLES
      t_outtab       = lt_display
    EXCEPTIONS
      program_error  = 1
      OTHERS         = 2.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: SALARY_REPORT
*& Generates a Department-wise Salary Summary Report
*& Shows: Dept | No. of Employees | Total Salary | Avg Salary | Max Salary
*&---------------------------------------------------------------------*

FORM salary_report.

  DATA: lt_fieldcat  TYPE slis_t_fieldcat_alv,
        ls_fieldcat  TYPE slis_fieldcat_alv,
        ls_layout    TYPE slis_layout_alv,
        lv_dept      TYPE char30,    " Current department being processed
        lv_count     TYPE i,         " Employee count for department
        lv_total     TYPE p DECIMALS 2,  " Total salary
        lv_max       TYPE p DECIMALS 2.  " Max salary

  " ----- Build the Salary Summary Report -----
  " We use SORT + LOOP to group by department

  " Sort employees by department first
  SORT gt_employees BY dept.

  " Loop through employees and group by department
  CLEAR: gt_salary_rpt, lv_dept, lv_count, lv_total, lv_max.

  LOOP AT gt_employees INTO gs_employee.

    " When department changes, save previous dept's summary
    IF lv_dept <> gs_employee-dept AND lv_dept IS NOT INITIAL.

      gs_salary_rpt-dept      = lv_dept.
      gs_salary_rpt-emp_count = lv_count.
      gs_salary_rpt-total_sal = lv_total.
      gs_salary_rpt-max_sal   = lv_max.
      IF lv_count > 0.
        gs_salary_rpt-avg_sal = lv_total / lv_count.
      ENDIF.
      APPEND gs_salary_rpt TO gt_salary_rpt.

      " Reset counters for next department
      CLEAR: lv_count, lv_total, lv_max.
    ENDIF.

    " Accumulate totals for current department
    lv_dept = gs_employee-dept.
    lv_count = lv_count + 1.
    lv_total = lv_total + gs_employee-salary.
    IF gs_employee-salary > lv_max.
      lv_max = gs_employee-salary.
    ENDIF.

  ENDLOOP.

  " Don't forget the LAST department (loop ends without saving it)
  IF lv_dept IS NOT INITIAL.
    gs_salary_rpt-dept      = lv_dept.
    gs_salary_rpt-emp_count = lv_count.
    gs_salary_rpt-total_sal = lv_total.
    gs_salary_rpt-max_sal   = lv_max.
    IF lv_count > 0.
      gs_salary_rpt-avg_sal = lv_total / lv_count.
    ENDIF.
    APPEND gs_salary_rpt TO gt_salary_rpt.
  ENDIF.

  " ----- Build Field Catalog for Salary Report -----
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'DEPT'.
  ls_fieldcat-seltext_l = 'Department'.
  ls_fieldcat-outputlen = 15.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'EMP_COUNT'.
  ls_fieldcat-seltext_l = 'Employees'.
  ls_fieldcat-outputlen = 10.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'TOTAL_SAL'.
  ls_fieldcat-seltext_l = 'Total Salary'.
  ls_fieldcat-outputlen = 15.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'AVG_SAL'.
  ls_fieldcat-seltext_l = 'Avg Salary'.
  ls_fieldcat-outputlen = 13.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'MAX_SAL'.
  ls_fieldcat-seltext_l = 'Highest Salary'.
  ls_fieldcat-outputlen = 15.
  APPEND ls_fieldcat TO lt_fieldcat.

  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_program_name = sy-repid
      it_fieldcat    = lt_fieldcat
      is_layout      = ls_layout
    TABLES
      t_outtab       = gt_salary_rpt
    EXCEPTIONS
      program_error  = 1
      OTHERS         = 2.

ENDFORM.

*& ===================================================================
*& INTERVIEW EXPLANATION GUIDE
*& ===================================================================
*&
*& "I built an Employee Directory System in ABAP that helps manage
*& employee records across departments. The key features are:"
*&
*& 1. ADD EMPLOYEE: Validates mandatory fields (ID, Name, Dept),
*&    checks for duplicate IDs, then APPENDs to the internal table.
*&
*& 2. SEARCH BY ID: Uses READ TABLE with key emp_id to find and
*&    display the employee profile using WRITE statements.
*&
*& 3. UPDATE DETAILS: READs existing record, updates only filled
*&    fields, uses MODIFY with INDEX to update the row.
*&
*& 4. DEPT-WISE LIST: Filters gt_employees by department using
*&    WHERE clause in LOOP, displays sorted ALV with dept grouping.
*&
*& 5. SALARY REPORT: Groups employees by department using SORT +
*&    LOOP, calculates total, average, max salary per dept,
*&    displays summary in ALV.
*&
*& KEY ABAP CONCEPTS:
*&  • Modularization: Each feature is a separate FORM/ENDFORM
*&  • LOOP AT ... WHERE: Filter during loop
*&  • SORT ... BY: Sort internal table
*&  • ALV Sort (it_sort): Built-in ALV column sorting
*&  • Aggregation: Calculating totals in a loop
*& ===================================================================
