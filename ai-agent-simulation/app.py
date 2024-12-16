from flask import Flask, jsonify, request, render_template
from ai import AI_Agent, Environment

app = Flask(__name__, static_url_path='/static', static_folder='static', template_folder='templates')

# Initialize environment and AI agent
env = Environment(grid_size=10, food_position=[5, 5], walls=[[3, 3], [4, 4]])
agent = AI_Agent(env)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/reset', methods=['POST'])
def reset_env():
    env.reset()
    state = env.get_state()
    return jsonify(state)

@app.route('/step', methods=['POST'])
def step():
    data = request.get_json()
    action = data.get('action')
    reward = agent.take_action(action)
    return jsonify({"reward": reward})

@app.route('/state', methods=['GET'])
def get_state():
    state = env.get_state()
    return jsonify(state)

if __name__ == "__main__":
    app.run(debug=True)
