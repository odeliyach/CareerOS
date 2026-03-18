# Customization Instructions for Job Search N8N

## Customizing for Different Job Types
To customize the system for different job types, follow these steps:
1. **Identify the Job Types**: List down the types of jobs you want to support.
2. **Modify Job Type Filters**: Navigate to the job type filtering feature in the workflow and update the filters to align with the new job types.
3. **Testing**: Ensure to run tests for each job type to verify that the system captures the correct data.

## Modifying Prompts
To modify prompts used in the system:
1. **Locate Prompt Configurations**: Find the section in the code where prompts are defined, typically in configuration files or environment variables.
2. **Edit Prompt Text**: Update the text to better fit the new context or information needs.
3. **Review Integration**: Ensure the modified prompts integrate seamlessly with existing conversation flows.

## Adding New Tiers
To add new tiers to the job classification:
1. **Define New Tiers**: Clearly define the new tiers you wish to introduce.
2. **Update System Configurations**: Go to the configuration settings where tiers are listed and add your new tiers.
3. **Modify Logic**: Update the logic where the tiers are utilized in the workflow to include your new additions.
4. **Test Scenarios**: Conduct tests to ensure the system handles the new tiers correctly.

## Conclusion
Customizing the system involves modifying filters, prompts, and classifications. Ensure to test all changes before deploying them to the live environment.