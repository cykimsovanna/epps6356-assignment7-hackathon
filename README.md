# epps6356-assignment7-hackathon

Susan Pompt to Gemini
I need help building an interactive R Shiny app for Assignment 7: Hackathon 2.0 using our team's EV dataset (ev_registration_report_20260101.xlsx, sheet 'County - Adoption'). Please create a complete app.R script for Chart 18 (Bubble Chart) with the following requirements:

Axes & Encoding:

X-axis: Total Electric Vehicles (Electric Vehicles)

Y-axis: EV Adoption Rate (Adoption Rate)

Bubble Size: Total Fleet Size (All Vehicles)

Interactivity & Filtering:

Include a multi-select dropdown for Texas counties that dynamically filters the chart in real-time when counties are added or removed.

Pre-select the 16 DFW counties by default so the app opens with them already populated.

Include a sidebar slider to filter counties by their total vehicle range.

Design & Tooltips:

Use ggplotly with custom, clean HTML tooltips showing County name, Electric Vehicles count, Adoption Rate percentage, and Total Fleet size.

Keep the code clean, modular, and ready to be integrated into our team's shared GitHub repository.