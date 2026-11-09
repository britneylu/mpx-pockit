"""Run only against local emulators; never touches a live Firebase project."""
import json
import os
import urllib.error
import urllib.request

PROJECT = 'demo-pockit'
firestore_host = os.environ.get('FIRESTORE_EMULATOR_HOST', '')
auth_host = os.environ.get('FIREBASE_AUTH_EMULATOR_HOST', '')
if not firestore_host.startswith(('127.0.0.1:', 'localhost:')) or not auth_host.startswith(('127.0.0.1:', 'localhost:')):
    raise SystemExit('Start both local emulators using the README command.')


def request(url, body=None, token=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            status, result = response.status, json.load(response)
    except urllib.error.HTTPError as error:
        status, result = error.code, json.load(error)
    assert status == expected, f'Expected {expected}, got {status}: {result}'
    return result


def account(email):
    result = request(f'http://{auth_host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key',
                     {'email': email, 'password': 'test-password123', 'returnSecureToken': True})
    return result['localId'], result['idToken']


uid, token = account('owner@example.com')
other_uid, other_token = account('other@example.com')
base = f'http://{firestore_host}/v1/projects/{PROJECT}/databases/(default)/documents'
path = f'users/{uid}/expenses/test-expense'
name = f'projects/{PROJECT}/databases/(default)/documents/{path}'
fields = {
    'amountMinor': {'integerValue': '1500'},
    'currency': {'stringValue': 'JPY'},
    'amountUsdMinor': {'integerValue': '1000'},
    'exchangeRate': {'doubleValue': 0.006667},
    'rateDate': {'timestampValue': '2026-01-01T00:00:00Z'},
    'expenseDate': {'timestampValue': '2026-01-01T00:00:00Z'},
    'category': {'stringValue': 'Food'},
    'description': {'stringValue': 'Lunch'},
}


def write(actor_token, values, expected=200):
    return request(base + ':commit', {'writes': [{
        'update': {'name': name, 'fields': values},
        'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}],
    }]}, actor_token, expected)


write(token, fields)
request(base + '/' + path, token=token)
request(base + '/' + path, token=other_token, expected=403)
request(base + '/' + path, expected=403)
write(other_token, fields, 403)
write(None, fields, 403)
write(token, {**fields, 'amountMinor': {'integerValue': '-1'}}, 403)
write(token, {**fields, 'currency': {'stringValue': 'INVALID'}}, 403)
write(token, {**fields, 'description': {'stringValue': 'x' * 201}}, 403)
write(token, {**fields, 'unexpected': {'stringValue': 'no'}}, 403)
write(token, {**fields, 'description': {'stringValue': 'Updated lunch'}})
request(base + ':commit', {'writes': [{'delete': name}]}, other_token, 403)
request(base + ':commit', {'writes': [{'delete': name}]}, token)
print('Firestore rules passed: owner CRUD, cross-account denial, signed-out denial, and field validation.')

# check owner access and field validation for monthly budget settings
budget_path = f'users/{uid}/settings/preferences'
budget_name = f'projects/{PROJECT}/databases/(default)/documents/{budget_path}'
budget_fields = {'monthlyBudgetMinor': {'integerValue': '120000'},
                 'reportingCurrency': {'stringValue': 'USD'}}
def budget_write(actor_token, values, expected=200):
    return request(base + ':commit', {'writes': [{
        'update': {'name': budget_name, 'fields': values},
        'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}],
    }]}, actor_token, expected)

budget_write(token, budget_fields)
request(base + '/' + budget_path, token=token)
request(base + '/' + budget_path, token=other_token, expected=403)
request(base + '/' + budget_path, expected=403)
budget_write(other_token, budget_fields, 403)
budget_write(None, budget_fields, 403)
for invalid in ['0', '-1', '1000000000001']:
    budget_write(token, {**budget_fields, 'monthlyBudgetMinor': {'integerValue': invalid}}, 403)
budget_write(token, {**budget_fields, 'monthlyBudgetMinor': {'doubleValue': 12.5}}, 403)
budget_write(token, {**budget_fields, 'reportingCurrency': {'stringValue': 'EUR'}}, 403)
budget_write(token, {**budget_fields, 'extra': {'stringValue': 'no'}}, 403)
budget_write(token, {**budget_fields, 'monthlyBudgetMinor': {'integerValue': '130000'}})
print('Budget rules passed: owner access, cross-account denial, and usd minor-unit validation')
