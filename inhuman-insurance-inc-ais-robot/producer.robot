*** Settings ***
Documentation       Inhuman Insurance, Inc. Artificial Intelligence System robot.
...                 Produces traffic data work items.

Library    RPA.Tables
Library    Collections
Resource    shared.robot

*** Variables ***
${traffic_json_file_path}=    ${OUTPUT_DIR}${/}traffic.json
# JSON data keys:
${COUNTRY_KEY}=    SpatialDim
${GENDER_KEY}=    Dim1
${RATE_KEY}=    NumericValue
${YEAR_KEY}=    TimeDim
${max_rate}=    ${5.0}
${both_genders}=    BTSX

*** Tasks ***
Produce traffic data work items
    Download Traffic Data
    ${traffic_data}=    Load traffic data as table
    ${filtered_data}=    Filter and sort traffic data    ${traffic_data}
    ${filtered_data}=    Get the latest data by country    ${filtered_data}
    ${payloads}=    Create work item payloads    ${filtered_data}
    Save work item payloads    ${payloads}

*** Keywords ***
Download Traffic Data
    #download data from given API Endpoint and store them in traffic.json file under output folder. 
    Download
    ...    https://github.com/robocorp/inhuman-insurance-inc/raw/main/RS_198.json
    ...    ${traffic_json_file_path}
    ...    overwrite=True

Load traffic data as table
    ${json}=    Load JSON from file    ${traffic_json_file_path}
    ${table}=    Create Table    ${json}[value]
    Return From Keyword    ${table}

Filter and sort traffic data
    [Arguments]    ${table}
    Filter Table By Column    ${table}    ${rate_key}    <    ${max_rate}
    Filter Table By Column    ${table}    ${gender_key}    ==    ${both_genders}
    Sort Table By Column    ${table}    ${year_key}    False
    Return From Keyword    ${table}

Get the latest data by country
    [Arguments]    ${table}
    ${table}=    Group Table By Column    ${table}    ${country_key}
    ${latest_data_by_country}=    Create List
    FOR    ${group}    IN    @{table}
        ${first_row}=    Pop Table Row    ${group}
        Append To List    ${latest_data_by_country}    ${first_row}   
    END 
    Return From Keyword    ${latest_data_by_country}

Create work item payloads
    [Arguments]    ${traffic_data}
    ${payloads}=    Create List
    FOR    ${row}    IN    @{traffic_data}
        ${payload}=
        ...    Create Dictionary
        ...    country=${row}[${COUNTRY_KEY}]
        ...    year=${row}[${YEAR_KEY}]
        ...    rate=${row}[${RATE_KEY}]
        Append To List    ${payloads}    ${payload}
    END
    Return From Keyword    ${payloads}

Save work item payloads
    [Arguments]    ${payloads}
    FOR    ${payload}    IN    @{payloads}
        Save work item payload    ${payload}
        
    END

Save work item payload
    [Arguments]    ${payload}
    ${variables}=    Create Dictionary    traffic_data=${payload}
    Create Output Work Item    variables=${variables}    save=True