from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/')
def hello_world():
    return "Hello, World! This is running inside a Docker container on ECS."

@app.route('/api/greet', methods=['GET'])
def greet():
    name = request.args.get('name', 'Stranger')
    return jsonify(message=f"Hello, {name}!")

@app.route('/api/data', methods=['POST'])
def receive_data():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    return jsonify({"received_data": data}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
