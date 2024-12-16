# AI Agent Simulation (2D)

This project demonstrates a simple reinforcement learning (Q-learning) agent navigating a 2D grid environment. The environment and AI logic run on a Flask backend, while the frontend is built with HTML, CSS, and JavaScript.

## Features
- **2D Grid Environment**: A 10x10 grid representing the simulation space.
- **AI Agent**: A blue square that learns to navigate towards the food.
- **Food**: A green square that the agent aims to reach.
- **Walls**: Gray squares that the agent must avoid.
- **Autonomous Movement**: The agent moves on its own based on learned policies.
- **Environment Randomization**: The environment randomizes every 100 epochs to introduce variability.
- **Real-time Visualization**: The grid updates dynamically to reflect the agent's actions and environment changes.

## Setup and Run

1. **Run the setup script:**
   ```
   ./setup.sh
   ```

2. **Activate the virtual environment:**
   ```
   source venv/bin/activate
   ```

3. **Run the Flask server:**
   ```
   python app.py
   ```

4. **Open [http://localhost:5000](http://localhost:5000) in your web browser.**

## Future Enhancements
- Implement more advanced AI algorithms.
- Introduce multiple agents.
- Add dynamic obstacles.
- Persist the AI's learning across sessions.
- Provide user controls to adjust AI parameters.

## License
MIT License
