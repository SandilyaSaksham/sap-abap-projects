# SAP ABAP Projects 

3 SAP ABAP programs demonstrating core concepts used in real SAP development.

## Projects

### 1. Student Management System (`ZSTUDENT_MGMT`)
Add, Update, Delete, Search student records with ALV grid report.

### 2. Employee Directory System (`ZEMP_DIRECTORY`)
Department-wise employee list and salary summary report with SORT + LOOP grouping logic.

### 3. Product Inventory Management (`ZPROD_INVENTORY`)
Stock tracking with Low Stock Alert Report using ALV traffic lights (Red = Out of Stock, Yellow = Low Stock).

## Concepts Used
- Internal Tables & Work Areas
- CRUD: APPEND / READ TABLE / MODIFY / DELETE
- ALV Grid Display (REUSE_ALV_GRID_DISPLAY)
- Selection Screen with Radio Buttons
- SORT + LOOP grouping for reports
- Business Validations & MESSAGE types
- sy-subrc, sy-tabix system variables

## How to Run
1. Open SAP GUI → Transaction `SE38`
2. Enter program name → Create → Paste code
3. Activate with `Ctrl+F3`
4. Execute with `F8`

## Tools
SAP GUI · ABAP Editor (SE38) · ALV Reports
