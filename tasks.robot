*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.HTTP
Library    RPA.Browser.Selenium
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive
Library    RPA.Robocorp.Vault

*** Variables ***
${RECEIPT_DIR}=    ${OUTPUT_DIR}${/}receipt
${SCREENSHOT_DIR}=    ${OUTPUT_DIR}${/}screenshot

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    ${secret}=    Get Secret    order_process_credentials
    ${endpoint_url}=    Set Variable    ${secret}[order_csv_url]
    Download    ${endpoint_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click Button When Visible    class=btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Click Element    xpath://label[./input[@value="${order}[Body]"]]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order    
    Wait Until Element Is Visible    id=receipt    

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${RECEIPT_DIR}${/}receipt_${order_number}.pdf
    [Return]    ${RECEIPT_DIR}${/}receipt_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview    ${SCREENSHOT_DIR}${/}screenshot_${order_number}.png
    [Return]    ${SCREENSHOT_DIR}${/}screenshot_${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${open_pdf}=    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}


Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}receipt_collection.zip
    Archive Folder With Zip
    ...    ${RECEIPT_DIR}
    ...    ${zip_file_name}



*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

