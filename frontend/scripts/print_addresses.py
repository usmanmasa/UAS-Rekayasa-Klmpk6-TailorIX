import json
p='frontend/tmp_tailors_response.json'
with open(p, encoding='utf-8') as f:
    data=json.load(f)
for t in data:
    print(json.dumps({'id': t.get('id'), 'shop_name': t.get('shop_name'), 'address': t.get('address')}, ensure_ascii=False))
