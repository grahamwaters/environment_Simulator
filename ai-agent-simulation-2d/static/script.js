const gridElement = document.getElementById("grid");
const resetButton = document.getElementById("reset-button");
const rewardElement = document.getElementById("reward");
const epochElement = document.getElementById("epoch");
const gridSize = 10;

// Render the grid based on state
function renderGrid(state) {
    gridElement.innerHTML = "";
    for (let y = 0; y < gridSize; y++) {
        for (let x = 0; x < gridSize; x++) {
            const cell = document.createElement("div");
            cell.classList.add("cell");
            // Check for walls
            state.walls.forEach(wall => {
                if (wall[0] === x && wall[1] === y) {
                    cell.classList.add("wall");
                }
            });
            // Check for food
            if (state.food_position[0] === x && state.food_position[1] === y) {
                cell.classList.add("food");
            }
            // Check for agent
            if (state.agent_position[0] === x && state.agent_position[1] === y) {
                cell.classList.add("agent");
            }
            gridElement.appendChild(cell);
        }
    }
    // Update reward display
    rewardElement.textContent = state.reward;
}

// Fetch initial state
async function initialize() {
    try {
        const response = await fetch("/reset", { method: "POST" });
        const data = await response.json();
        renderGrid(data);
        epochElement.textContent = "0";
    } catch (error) {
        console.error("Error initializing simulation:", error);
    }
}

// Handle reset button
resetButton.addEventListener("click", initialize);

// Fetch and render state periodically
let currentEpoch = 0;
setInterval(async () => {
    try {
        const stateResponse = await fetch("/state");
        const stateData = await stateResponse.json();
        renderGrid(stateData);
        epochElement.textContent = currentEpoch;
    } catch (error) {
        console.error("Error fetching state:", error);
    }
}, 500); // Update every 500ms

// Initialize on page load
window.onload = initialize;
