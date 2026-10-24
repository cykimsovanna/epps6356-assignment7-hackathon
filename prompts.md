# EPPS 6356 – Assignment 7: Hackathon 2.0

## AI Prompt Documentation

This document contains the AI prompts used by our team
during the development of our EV adoption and charging
infrastructure visualization project.

---

# Yuddh – ChatGPT Prompts

## AI Tool: ChatGPT

(Reference Repository)

---

# Susan – Gemini Prompts

## AI Tool: Google Gemini

### Prompt 1: Interactive Bubble Chart

I need help building an interactive R Shiny app for Assignment 7: Hackathon 2.0 using our team's EV dataset (ev_registration_report_20260101.xlsx, sheet 'County - Adoption'). 
Please create a complete app.R script for Chart 18 (Bubble Chart) with the following requirements: 
Axes & Encoding:
X-axis:Total Electric Vehicles (Electric Vehicles)
Y-axis: EV Adoption Rate (Adoption Rate)
Bubble Size: Total Fleet Size (All Vehicles)
Interactivity & Filtering: 
Include a multi-select dropdown for Texas counties that dynamically filters the chart in real-time when counties are added or removed.
Pre-select the 16 DFW counties by default so the app opens with them already populated.
Include a sidebar slider to filter counties by their total vehicle range.
Design & Tooltips:
Use ggplotly with custom, clean HTML tooltips showing County name, Electric Vehicles count, Adoption Rate percentage, and Total Fleet size.
Keep the code clean, modular, and ready to be integrated into our team's shared GitHub repository.


---

# Rose – ChatGPT Prompts

## AI Tool: ChatGPT-6

### 1. Troubleshooting R Code

Troubleshooting RCode: 
Prompt/Error 1: Error in library(sf): there is no package called 'sf'
Prompt/Error 2:Error in library(tidycensus): there is no package called 'tidycensus'
Prompt/Error 3:Error in get_census_api_key(): A Census API key is required for tidycensus requests.
Prompt/Error 4:Error in library(plotly): there is no package called 'plotly'

Visualization Design and Refinements:
Prompt 1: Improving the Initial Design: "Center 'Sources: DFW Clean Cities...' to the middle and make it look cleaner. Use the attached as a reference. I want to keep the same data except make it look more aesthetically pleasing."
Prompt 2: Improving Readability: "Move where it says 'registrations, charging stations, charging ports etc.' to the left side of the chart in a neat manner. Make the circles on the graph itself bigger. It is difficult to see the names of the counties. Make sure they are clean and concise and easy to read without any clutter."
Prompt 3: Creating a Two-Column Layout: "Move all of the words on the left side of the graph, except for the 'Sources: DFW Clean Cities...'. Keep that as it is. The graph itself should be on the right side."
Prompt 4: Adjusting Typography and Spacing: "Decrease the font size of 'EV Adoption and Charging...'. Move 'Measurements' lower on the page. Shorten 'Comparing EV registration...'. Keep the graph as is."
Prompt 5: Correcting Overlapping Text: "Per the screenshot attached, the words are overlapping. Please fix this. Keep the graph as is."
Prompt 6: Finalizing the Visualization: "Change the small text ... to 'Data Year: January 1, 2026 Normalized to a 0–100 scale.' Change 'EV Adoption and Charging Infrastructure Across DFW' to 'EV Adoption and Charging Infrastructure Across 16 DFW Counties.' Make 'Sources: DFW Clean Cities EV Registration...' one continuous line."

Final Code and GitHub Integration: 
After completing the design revisions, I requested the full updated R script so I could copy and paste it into RStudio.
