*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Excel.Application
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Desktop
Library    RPA.FileSystem
Library    RPA.Archive
Library    String
Library    RPA.Robocorp.Vault

*** Variables ***
${download_dir}=    "./data"

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${vault_data}=    Get Secret    OrderRobot
    ${url}=    set Variable    ${vault_data}[website_URL]
    ${download_url}=    set Variable    ${vault_data}[download_URL]
    Launch website    ${url}
    Wait Until Keyword Succeeds    3x    1s    Navigate to Order your robot tab
    Wait Until Keyword Succeeds    3x    1s    click ok
    Download data    ${download_url}
    Process orders
    Collect PDFs and Create ZIP
    Clean output dir
    [Teardown]    Log out and close the browser

*** Keywords ***
Launch website
    [Arguments]    ${url}
    Close Browser
    Open Available Browser    ${url}

Navigate to Order your robot tab
    Click Link    Order your robot!

click ok
    Click Button    OK
Download data
    [Arguments]    ${download_url}
    Set Download Directory    ${download_dir}
    Download    ${download_url}    overwrite=True    

Process orders
    #${order_number}=    Set Variable    ${1}
    ${orders}=   Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Fill & Submit order form    ${order}
        #${order_number}=    Evaluate    ${order_number} + 1
        
    END
Fill & Submit order form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Click Element    id:id-body-${order}[Head]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Keyword Succeeds    10x    1s    Submit order
    Take screenshot    ${order}[Order number]
    Export receipt as PDF    ${order}[Order number]
    Click Button    id:order-another
    click ok


Submit order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Take screenshot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshot_${order_number}.png
Export receipt as PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${current_PDF}=    Set Variable    ${OUTPUT_DIR}${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt}    ${current_PDF}
    ${receipt_pdf}=    Open Pdf    ${current_PDF}
    ${current_ss}=    Create List    ${current_PDF}
    ...    ${OUTPUT_DIR}${/}screenshot_${order_number}.png
    Add Files To Pdf    ${current_ss}    ${current_PDF}
    Close Pdf

Collect PDFs and Create ZIP
    Archive Folder With Zip    ${OUTPUT_DIR}${/}   ${OUTPUT_DIR}${/}order_receipts.zip    include=*.pdf

Clean output dir
    #remove pdfs
    ${files}=    Find Files    ${OUTPUT_DIR}${/}**/*.pdf
    FOR    ${path}    IN    @{files}
        #${fileext}=    Set Variable    Get File Extension    ${path}
        Remove File    ${path}
    END
    
    #remove screenshots
    ${files}=    Find Files    ${OUTPUT_DIR}${/}**/*.png
    FOR    ${path}    IN    @{files}
        #${fileext}=    Set Variable    Get File Extension    ${path}
        Remove File    ${path}
    END
Log out and close the browser
    Close Browser