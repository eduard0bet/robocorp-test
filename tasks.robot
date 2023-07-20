*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Tables
Library             RPA.Desktop


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create Folder
    Open the robot order website
    Download the Excel File
    Order the Robots
    Create ZIP package
    [Teardown]    Close Browser


*** Keywords ***
Create Folder
    Create Directory    ${CURDIR}${/}receipts
    Create Directory    ${CURDIR}${/}images

Create ZIP package
    Archive Folder With Zip    ${CURDIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Order the Robots
    ${robots}=    Read Table From Csv    orders.csv    header=True

    FOR    ${robot}    IN    @{robots}
        Wait And Click Button    //button[@class="btn btn-dark"]
        Fill the info for a single robot    ${robot}
        Submit Robot
        Make the reciept    ${robot}
        Wait And Click Button    //button[@id='order-another']
    END

Fill the info for a single robot
    [Arguments]    ${robot}
    # Wait for element to load
    Wait Until Element Is Visible    head
    # Select the head
    Select From List By Value    head    ${robot}[Head]

    # Select the Body
    Click Element    id-body-${robot}[Body]

    # Select the Legs
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${robot}[Legs]

    # Shipping Address
    Input Text    address    ${robot}[Address]

    # Preview the Robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit Robot
    # Click Submit
    FOR    ${index}    IN RANGE    10
        Click Button    //button[@id="order"]
        ${alert}=    Run Keyword And Return Status    Element Should Be Visible    receipt

        # Check if the element is visible (success), then exit the loop
        IF    ${alert}    BREAK
    END

Make the reciept
    [Arguments]    ${robot}
    # Make the Order Reciept as a PDF
    ${pdf}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${pdf}    ${CURDIR}${/}receipts${/}${robot}[Order number].pdf

    # Take a ScreenShot of the Image
    ${img}=    Screenshot    robot-preview-image    ${CURDIR}${/}images${/}${robot}[Order number].png

    # Embed Image to PDF
    Add Watermark Image To Pdf
    ...    ${CURDIR}${/}images${/}${robot}[Order number].png
    ...    ${CURDIR}${/}receipts${/}${robot}[Order number].pdf
    ...    ${CURDIR}${/}receipts${/}${robot}[Order number].pdf

Download the Excel File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
