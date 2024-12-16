using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class DraggableWithPhysics : MonoBehaviour
{
    private bool isDragging = false; // Tracks if the object is being dragged
    private Vector3 offset; // Stores the offset between the mouse and the object's position
    private Camera mainCamera; // Reference to the main camera
    private Rigidbody2D rb; // Reference to the Rigidbody2D component
    private Vector2 lastVelocity; // Tracks the velocity during dragging

    public float throwForceMultiplier = 5f; // Adjust to control how much momentum is applied after drag
    public float maxThrowForce = 20f; // Limit to prevent excessive throwing force
    public float gravityScale = 1f; // Custom gravity scale during dragging

    void Start()
    {
        mainCamera = Camera.main;
        rb = GetComponent<Rigidbody2D>();

        // Set initial gravity scale
        rb.gravityScale = gravityScale;
    }

    void OnMouseDown()
    {
        // Set dragging to true and disable natural movement
        isDragging = true;
        rb.velocity = Vector2.zero; // Stop motion during dragging
        rb.gravityScale = 0; // Disable gravity while dragging

        // Calculate the offset between the object's position and the mouse position
        Vector3 mousePosition = GetMouseWorldPosition();
        offset = transform.position - mousePosition;
    }

    void OnMouseUp()
    {
        // Stop dragging and re-enable gravity
        isDragging = false;
        rb.gravityScale = gravityScale;

        // Apply a force to the Rigidbody2D to simulate momentum
        Vector2 throwForce = Vector2.ClampMagnitude(lastVelocity * throwForceMultiplier, maxThrowForce);
        rb.AddForce(throwForce, ForceMode2D.Impulse);
    }

    void Update()
    {
        if (isDragging)
        {
            // Update the object's position to follow the mouse while maintaining the offset
            Vector3 mousePosition = GetMouseWorldPosition();
            Vector3 newPosition = mousePosition + offset;

            // Update the Rigidbody2D's position for smooth physics integration
            rb.MovePosition(newPosition);

            // Calculate velocity based on change in position
            lastVelocity = (newPosition - transform.position) / Time.deltaTime;
        }
    }

    private Vector3 GetMouseWorldPosition()
    {
        // Convert the mouse position from screen space to world space
        Vector3 mousePosition = Input.mousePosition;
        mousePosition.z = 10f; // Set a fixed distance from the camera
        return mainCamera.ScreenToWorldPoint(mousePosition);
    }
}
