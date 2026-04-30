# Project Overview

This document outlines the requirements for a standalone, offline-first mobile application designed to track personal finances and calculate net worth. The app will allow users to record assets, available funds, and track incoming and outgoing payments.

Technical Stack

Framework: Flutter (Deployable to iOS and Android)

Database: SQLite (Local storage only, no external server or API requirements)

State Management: Developer's discretion (e.g., Provider, Riverpod, Bloc)

Core Data Models (SQLite Schema)
The database will consist of four primary tables.

1. Available Funds

ID: Integer (Primary Key, Auto-increment)

Name: Text

Description: Text

Amount: Real/Decimal (Current balance)

2. Available Assets

ID: Integer (Primary Key, Auto-increment)

Name: Text

Description: Text

Amount: Real/Decimal (Current estimated value)

3. Incoming Payments

ID: Integer (Primary Key, Auto-increment)

Name: Text

Description: Text

Amount: Real/Decimal

IsCompleted: Boolean (Default: False)

TargetFundId: Integer (Foreign Key referencing Available Funds ID)

4. Outgoing Payments

ID: Integer (Primary Key, Auto-increment)

Name: Text

Description: Text

Amount: Real/Decimal

IsCompleted: Boolean (Default: False)

SourceFundId: Integer (Foreign Key referencing Available Funds ID)

Key Features & Business Logic
Dashboard & Summary

Net Worth Calculation: Display the user's total net worth, calculated as the sum of all Available Funds and Available Assets.

Pending Cash Flow: Display a summary of total pending Incoming Payments and total pending Outgoing Payments.

Visuals: Provide a simple, clean overview of the four categories for quick reference.

Item Management (CRUD Operations)

Create: Users must be able to add new items to all four categories using a standard form (Name, Description, Amount).

Read: Display lists of items for each category.

Update: Users can edit the details of existing entries.

Delete: Users can remove entries.

Transaction Processing (The "Completion" Workflow)

Payment Linking: When creating an Incoming or Outgoing payment, the UI must require the user to select an existing "Available Fund" from a dropdown list to serve as the source or destination.

Incoming Completion: When an Incoming Payment is toggled from "Pending" to "Completed", the app must automatically add the payment Amount to the linked TargetFundId's balance.

Outgoing Completion: When an Outgoing Payment is toggled from "Pending" to "Completed", the app must automatically subtract the payment Amount from the linked SourceFundId's balance.

Reversal Logic (Optional but recommended): If a user unmarks a completed payment back to pending, the app should reverse the mathematical operation on the linked fund.

User Interface Requirements
General Navigation

A bottom navigation bar or side menu to switch between the Dashboard, Funds, Assets, Incoming, and Outgoing views.

Forms and Inputs

Standardized text fields for Name and Description.

Numeric-only keyboards for Amount fields.

Clear toggle switches or checkboxes for the IsCompleted status on payment items