*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.FileSystem
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.HTTP
Library             RPA.Tables


*** Variables ***
${url}                          https://robotsparebinindustries.com/#/robot-order
${csv_url}                      https://robotsparebinindustries.com/orders.csv
${download_path}                ${TEMPDIR}/orders.csv
${PDF_TEMP_OUTPUT_DIRECTORY}    ${OUTPUT_DIR}/PDFs
${base_url}                     https://robotsparebinindustries.com/
${pdf_file_extension}           .pdf
${zip_file_extension}           .zip
${order_number}
${csv_file}                     path/to/your/csv/file.csv
${output_folder}                path/to/your/output/folder


*** Tasks ***
Download CSV file with order data and save orders with screenshot and receipts
    Open order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Click Order
        Store receipt as PDF    ${row}
        Take screenshot of robot    ${row}
        Embed the screenshot to the receipt PDF file    ${row}
        Go to order another robot
    END


*** Keywords ***
Open order website
    Open Available Browser    ${url}

Close the annoying modal
    Click Button    Yep

Get orders
    Download    url=${csv_url}    target_file=${download_path}    overwrite=True
    ${table}=    Read table from CSV    path=${download_path}
    RETURN    ${table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Wait And Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Click Order
    Wait Until Keyword Succeeds    5x    0.5 sec    Submit Order

Submit Order
    Wait And Click Button    id:order
    Is Element Visible    id:order-completion    missing_ok=False

Read table from CSV into tables
    [Arguments]    ${download_path}
    ${Orders}=
    ...    Read table from CSV    ${download_path}
    ...    header=true
    RETURN    ${Orders}

Go to order another robot
    Wait And Click Button    id:order-another

Take screenshot of robot
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/Pictures${/}${row}[Order number].png

Store receipt as PDF
    [Arguments]    ${row}
    ${recipt_element}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${recipt_element}    ${OUTPUT_DIR}/PDFs${/}${row}[Order number].pdf    overwrite=True

Embed the screenshot to the receipt PDF file
    [Arguments]    ${row}
    Open Pdf    ${OUTPUT_DIR}/PDFs${/}${row}[Order number].pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}/Pictures${/}${row}[Order number].png
    ...    ${OUTPUT_DIR}/PDFs${/}${row}[Order number].pdf

Create a Zip File of the Receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}
