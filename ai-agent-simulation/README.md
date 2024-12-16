# AI Agent Simulation with Three.js

This project demonstrates a simple reinforcement learning (Q-learning) agent navigating a 3D grid environment rendered using Three.js in a web browser. The environment and AI logic run on a Flask backend.

## Features
- A 10x10 grid environment.
- A single AI agent that moves using keyboard input (arrow keys).
- The agent receives rewards for reaching food and penalties for hitting walls.
- The environment is visualized in 3D using Three.js, with realistic lighting.
- Easy setup with a single `setup.sh` script.

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

5. **Use arrow keys to move the agent around.**

## Future Enhancements
- More complex AI algorithms.
- Dynamic obstacles.
- Persistent Q-table saving/loading.

## License
MIT License
