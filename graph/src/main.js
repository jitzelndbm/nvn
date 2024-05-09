import MultiGraph from "graphology";
import ForceSupervisor from "graphology-layout-force/worker";
import Sigma from "sigma";

export default function myGraph(nodes, edges) {
	const container = document.getElementById("container");

	// Create a graphology graph
	const graph = new MultiGraph();

	let i = 0;
	nodes.forEach(el => {
		graph.addNode(el, { label: "Note", x: i, y: i, size: 10, color: "blue" });
		i++;
	});

	edges.forEach(el => {
		graph.addEdge(el[0], el[1], { size: 1, color: "purple" });
	});

	// Create the spring layout and start it
	const layout = new ForceSupervisor(graph, { isNodeFixed: (_, attr) => attr.highlighted });
	layout.start();

	const renderer = new Sigma(graph, container);

	//
	// Drag'n'drop feature
	//

	let draggedNode = null;
	let isDragging = false;

	// On mouse down on node, highlight it
	renderer.on("downNode", (e) => {
		isDragging = true;
		draggedNode = e.node;
		graph.setNodeAttribute(draggedNode, "highlighted", true);
	});

	// Move logic
	renderer.getMouseCaptor().on("mousemovebody", (e) => {
		if (!isDragging || !draggedNode) return;

		const pos = renderer.viewportToGraph(e);

		graph.setNodeAttribute(draggedNode, "x", pos.x);
		graph.setNodeAttribute(draggedNode, "y", pos.y);

		e.preventSigmaDefault();
		e.original.preventDefault();
		e.original.stopPropagation();
	});

	// Mouse up logic
	renderer.getMouseCaptor().on("mouseup", () => {
		if (draggedNode) {
			graph.removeNodeAttribute(draggedNode, "highlighted")
		}

		isDragging = false;
		draggedNode = null;
	});
}
