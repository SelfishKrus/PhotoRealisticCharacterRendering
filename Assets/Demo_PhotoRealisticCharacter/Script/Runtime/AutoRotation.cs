using UnityEngine;

public class AutoRotation : MonoBehaviour
{

    public bool isRotate;
    public float speed = 10f;
    public float totalAngleToStop = 360f;

    float initialRotationY;
    float totalAngle;
    

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        initialRotationY = transform.eulerAngles.y;
    }

    // Update is called once per frame
    void Update()
    {   
        float angle = speed * Time.deltaTime;
        if (isRotate)
        {
            totalAngle += angle;

            transform.Rotate(0, angle, 0, Space.World);
            initialRotationY = transform.eulerAngles.y;
        }

        if (totalAngle >= totalAngleToStop)
        {
            isRotate = false;
        }
    }
}
