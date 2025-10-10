import logging

# Configure the logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        user_attributes = event['request']['userAttributes']
        aad_groups = user_attributes.get('custom:AadGroups')
        email = user_attributes.get('email')

        # Update the event with claims and scopes if the response structure exists
        if 'response' in event and 'claimsAndScopeOverrideDetails' in event['response']:
            event['response']['claimsAndScopeOverrideDetails'] = {
                "accessTokenGeneration": {
                    "claimsToAddOrOverride": {
                        "aad:groups": aad_groups,
                        "custom:AadGroups": aad_groups,
                        "email": email,
                    }
                }
            }
    except Exception as e:
        logger.error('Failed to extract attributes from Cognito event: %s', e)
    
    return event