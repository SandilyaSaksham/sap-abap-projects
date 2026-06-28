*&---------------------------------------------------------------------*
*& Program  : ZSTUDENT_MGMT
*& Title    : Student Management System
*& Author   : [Your Name]
*& Date     : 2024
*& Description: A complete student management system with Add, Update,
*&              Delete, Search, and ALV Report functionality.
*&---------------------------------------------------------------------*

REPORT zstudent_mgmt.

*&---------------------------------------------------------------------*
*& STEP 1: INCLUDE NECESSARY TYPE POOLS
*&---------------------------------------------------------------------*
" ALV (SAP List Viewer) needs these type pools
TYPE-POOLS: slis.   " Contains types used for ALV Grid

*&---------------------------------------------------------------------*
*& STEP 2: DEFINE CUSTOM TABLE (in real SAP, this is created in SE11)
*&         Here we simulate it using a GLOBAL INTERNAL TABLE
*&         Table Name: ZSTUDENTS
*&         Fields: Student ID, Name, Age, Course, Marks, Email
*&---------------------------------------------------------------------*

" This structure defines ONE student record (like a row in a table)
TYPES: BEGIN OF ty_student,
         stud_id  TYPE char10,    " Student ID (Primary Key)
         name     TYPE char50,    " Student Full Name
         age      TYPE numc3,     " Age (3 digit number)
         course   TYPE char30,    " Course Name e.g. B.Tech, MBA
         marks    TYPE p DECIMALS 2, " Marks out of 100
         email    TYPE char50,    " Email Address
       END OF ty_student.

" Internal Table = collection of student records (like a database table)
DATA: gt_students TYPE TABLE OF ty_student,   " Main table (global)
      gs_student  TYPE ty_student.            " Single work area (one row)

*&---------------------------------------------------------------------*
*& STEP 3: SELECTION SCREEN
*& This is the initial screen the user sees when they run the program
*& SE38 → Run → This screen appears
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  " Radio Buttons - user selects ONE action at a time
  PARAMETERS: rb_add  RADIOBUTTON GROUP grp1 DEFAULT 'X', " Add Student
              rb_upd  RADIOBUTTON GROUP grp1,              " Update Student
              rb_del  RADIOBUTTON GROUP grp1,              " Delete Student
              rb_srch RADIOBUTTON GROUP grp1,              " Search Student
              rb_list RADIOBUTTON GROUP grp1.              " View All (ALV)

SELECTION-SCREEN END OF BLOCK b1.

" Block for entering student data
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS: p_id    TYPE char10 LOWER CASE,  " Student ID
              p_name  TYPE char50 LOWER CASE,  " Name
              p_age   TYPE numc3,              " Age
              p_crs   TYPE char30 LOWER CASE,  " Course
              p_marks TYPE p DECIMALS 2,       " Marks
              p_email TYPE char50 LOWER CASE.  " Email

SELECTION-SCREEN END OF BLOCK b2.

*&---------------------------------------------------------------------*
*& STEP 4: INITIALIZATION
*& Runs once before the selection screen appears
*& We load some sample data here so the program works from the start
*&---------------------------------------------------------------------*

INITIALIZATION.

  " Set Title for Block 1
  TEXT-001 = 'Select Action'.
  TEXT-002 = 'Student Details'.

  " Pre-load 3 sample students for demo purposes
  CLEAR gs_student.
  gs_student-stud_id = 'STU001'.
  gs_student-name    = 'Rahul Sharma'.
  gs_student-age     = '20'.
  gs_student-course  = 'B.Tech CSE'.
  gs_student-marks   = '85.50'.
  gs_student-email   = 'rahul@email.com'.
  APPEND gs_student TO gt_students.

  CLEAR gs_student.
  gs_student-stud_id = 'STU002'.
  gs_student-name    = 'Priya Verma'.
  gs_student-age     = '21'.
  gs_student-course  = 'MBA Finance'.
  gs_student-marks   = '91.00'.
  gs_student-email   = 'priya@email.com'.
  APPEND gs_student TO gt_students.

  CLEAR gs_student.
  gs_student-stud_id = 'STU003'.
  gs_student-name    = 'Amit Singh'.
  gs_student-age     = '22'.
  gs_student-course  = 'BCA'.
  gs_student-marks   = '76.25'.
  gs_student-email   = 'amit@email.com'.
  APPEND gs_student TO gt_students.

*&---------------------------------------------------------------------*
*& STEP 5: START-OF-SELECTION
*& This runs when user clicks Execute (F8) on the selection screen
*&---------------------------------------------------------------------*

START-OF-SELECTION.

  " Check which radio button is selected and call the right form
  IF rb_add = 'X'.
    PERFORM add_student.       " Call ADD form

  ELSEIF rb_upd = 'X'.
    PERFORM update_student.    " Call UPDATE form

  ELSEIF rb_del = 'X'.
    PERFORM delete_student.    " Call DELETE form

  ELSEIF rb_srch = 'X'.
    PERFORM search_student.    " Call SEARCH form

  ELSEIF rb_list = 'X'.
    PERFORM display_alv.       " Call ALV REPORT form

  ENDIF.

*&---------------------------------------------------------------------*
*& FORM: ADD_STUDENT
*& Adds a new student to the internal table
*& Validation: Checks if ID already exists
*&---------------------------------------------------------------------*

FORM add_student.

  DATA: lv_found TYPE char1.  " Local variable to track if ID exists

  " Basic Validation - ID and Name are mandatory
  IF p_id IS INITIAL.
    MESSAGE 'Please enter Student ID!' TYPE 'E'.
    RETURN.
  ENDIF.

  IF p_name IS INITIAL.
    MESSAGE 'Please enter Student Name!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Check if Student ID already exists (no duplicates allowed)
  lv_found = space.
  READ TABLE gt_students INTO gs_student
             WITH KEY stud_id = p_id.
  IF sy-subrc = 0.  " sy-subrc = 0 means record FOUND
    MESSAGE 'Student ID already exists! Use Update instead.' TYPE 'E'.
    RETURN.
  ENDIF.

  " All validations passed → Add the new student
  CLEAR gs_student.
  gs_student-stud_id = p_id.
  gs_student-name    = p_name.
  gs_student-age     = p_age.
  gs_student-course  = p_crs.
  gs_student-marks   = p_marks.
  gs_student-email   = p_email.

  APPEND gs_student TO gt_students.  " Add to table

  " Show success message
  MESSAGE |Student { p_id } added successfully!| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: UPDATE_STUDENT
*& Updates an existing student's details
*& Only updates fields that are filled in (non-blank)
*&---------------------------------------------------------------------*

FORM update_student.

  DATA: lv_tabix TYPE i.  " Stores the index (row number) of the record

  " Student ID is needed to find the record
  IF p_id IS INITIAL.
    MESSAGE 'Please enter Student ID to update!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Search for the student in the table
  READ TABLE gt_students INTO gs_student
             WITH KEY stud_id = p_id.

  IF sy-subrc <> 0.  " sy-subrc <> 0 means NOT FOUND
    MESSAGE |Student { p_id } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  lv_tabix = sy-tabix.  " Save the row position

  " Update only the fields that are filled in
  IF p_name IS NOT INITIAL.
    gs_student-name = p_name.
  ENDIF.

  IF p_age IS NOT INITIAL.
    gs_student-age = p_age.
  ENDIF.

  IF p_crs IS NOT INITIAL.
    gs_student-course = p_crs.
  ENDIF.

  IF p_marks IS NOT INITIAL.
    gs_student-marks = p_marks.
  ENDIF.

  IF p_email IS NOT INITIAL.
    gs_student-email = p_email.
  ENDIF.

  " Write the updated record BACK to the same position in the table
  MODIFY gt_students FROM gs_student INDEX lv_tabix.

  MESSAGE |Student { p_id } updated successfully!| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DELETE_STUDENT
*& Deletes a student record by Student ID
*&---------------------------------------------------------------------*

FORM delete_student.

  " Student ID is needed to delete
  IF p_id IS INITIAL.
    MESSAGE 'Please enter Student ID to delete!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Search for the student
  READ TABLE gt_students INTO gs_student
             WITH KEY stud_id = p_id.

  IF sy-subrc <> 0.
    MESSAGE |Student { p_id } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  " Delete the record where stud_id matches
  DELETE gt_students WHERE stud_id = p_id.

  MESSAGE |Student { p_id } deleted successfully!| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: SEARCH_STUDENT
*& Searches for a student and displays their details
*&---------------------------------------------------------------------*

FORM search_student.

  IF p_id IS INITIAL.
    MESSAGE 'Please enter Student ID to search!' TYPE 'E'.
    RETURN.
  ENDIF.

  " Search in the internal table
  READ TABLE gt_students INTO gs_student
             WITH KEY stud_id = p_id.

  IF sy-subrc <> 0.
    MESSAGE |Student { p_id } not found!| TYPE 'E'.
    RETURN.
  ENDIF.

  " Display the found student details using WRITE statements
  WRITE: / '================================================'.
  WRITE: / '           STUDENT DETAILS'.
  WRITE: / '================================================'.
  WRITE: / 'Student ID :', gs_student-stud_id.
  WRITE: / 'Name       :', gs_student-name.
  WRITE: / 'Age        :', gs_student-age.
  WRITE: / 'Course     :', gs_student-course.
  WRITE: / 'Marks      :', gs_student-marks.
  WRITE: / 'Email      :', gs_student-email.
  WRITE: / '================================================'.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DISPLAY_ALV
*& Shows all students in a professional ALV Grid Report
*& ALV = ABAP List Viewer - gives a nice table view with sort/filter
*&---------------------------------------------------------------------*

FORM display_alv.

  " ALV needs a Field Catalog - it defines the COLUMNS of the report
  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,   " Table of column definitions
        ls_fieldcat TYPE slis_fieldcat_alv,       " One column definition
        ls_layout   TYPE slis_layout_alv.         " ALV Layout settings

  " ----- STEP 1: Define each column -----

  " Column 1: Student ID
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname  = 'STUD_ID'.   " Must match structure field name
  ls_fieldcat-seltext_l  = 'Student ID'." Column header (long text)
  ls_fieldcat-outputlen  = 12.          " Column width
  APPEND ls_fieldcat TO lt_fieldcat.

  " Column 2: Name
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'NAME'.
  ls_fieldcat-seltext_l = 'Student Name'.
  ls_fieldcat-outputlen = 25.
  APPEND ls_fieldcat TO lt_fieldcat.

  " Column 3: Age
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'AGE'.
  ls_fieldcat-seltext_l = 'Age'.
  ls_fieldcat-outputlen = 5.
  APPEND ls_fieldcat TO lt_fieldcat.

  " Column 4: Course
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'COURSE'.
  ls_fieldcat-seltext_l = 'Course'.
  ls_fieldcat-outputlen = 20.
  APPEND ls_fieldcat TO lt_fieldcat.

  " Column 5: Marks
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'MARKS'.
  ls_fieldcat-seltext_l = 'Marks'.
  ls_fieldcat-outputlen = 8.
  APPEND ls_fieldcat TO lt_fieldcat.

  " Column 6: Email
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'EMAIL'.
  ls_fieldcat-seltext_l = 'Email Address'.
  ls_fieldcat-outputlen = 30.
  APPEND ls_fieldcat TO lt_fieldcat.

  " ----- STEP 2: ALV Layout Settings -----
  ls_layout-zebra      = 'X'.  " Alternating row colors (easier to read)
  ls_layout-colwidth_optimize = 'X'.  " Auto-fit column widths

  " ----- STEP 3: Check if table has data -----
  IF gt_students IS INITIAL.
    MESSAGE 'No student records found!' TYPE 'I'.
    RETURN.
  ENDIF.

  " ----- STEP 4: Call the ALV Function Module -----
  " This is the standard SAP function that displays the ALV grid
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_program_name = sy-repid        " Current program name
      it_fieldcat    = lt_fieldcat     " Column definitions
      is_layout      = ls_layout       " Layout settings
    TABLES
      t_outtab       = gt_students     " The data to display
    EXCEPTIONS
      program_error  = 1
      OTHERS         = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error displaying ALV report!' TYPE 'E'.
  ENDIF.

ENDFORM.

*& ===================================================================
*& HOW THIS PROGRAM WORKS - QUICK EXPLANATION FOR INTERVIEW
*& ===================================================================
*&
*& 1. USER RUNS THE PROGRAM (SE38 → F8)
*&    → Selection screen appears with 5 radio buttons + input fields
*&
*& 2. TO ADD A STUDENT:
*&    → Select "Add Student" radio button
*&    → Fill in ID, Name, Age, Course, Marks, Email
*&    → Press F8 → FORM add_student runs
*&    → Validates data → APPENDs to gt_students table
*&
*& 3. TO UPDATE A STUDENT:
*&    → Select "Update Student" radio button
*&    → Enter the Student ID + new values
*&    → FORM update_student: READs the record, MODIFYs it
*&
*& 4. TO DELETE A STUDENT:
*&    → Select "Delete Student" radio button
*&    → Enter Student ID
*&    → FORM delete_student: DELETEs from table WHERE stud_id = p_id
*&
*& 5. TO SEARCH A STUDENT:
*&    → Select "Search" → Enter ID
*&    → FORM search_student: READ TABLE → WRITE details on screen
*&
*& 6. TO VIEW ALL STUDENTS (ALV REPORT):
*&    → Select "Student List" radio button
*&    → FORM display_alv: Builds field catalog → Calls ALV FM
*&    → Professional table view with sort/filter capability
*&
*& KEY ABAP CONCEPTS USED:
*&  • TYPES / DATA     - Define structures and internal tables
*&  • SELECTION-SCREEN - Input screen with radio buttons
*&  • INITIALIZATION   - Load sample data at startup
*&  • PERFORM / FORM   - Modular code (subroutines)
*&  • APPEND           - Add a row to internal table
*&  • READ TABLE       - Search a row in internal table
*&  • MODIFY           - Update a row in internal table
*&  • DELETE           - Remove a row from internal table
*&  • REUSE_ALV_GRID_DISPLAY - Standard SAP ALV Function Module
*& ===================================================================
