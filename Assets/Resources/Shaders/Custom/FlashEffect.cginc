float lightIntensity(float x, float directionOffset, float frequency, float clampValue, float density, float phaseShift)
{
    float location = x * frequency + directionOffset;
    return smoothstep(clampValue, 1, sin(location + phaseShift) * 0.5 + 0.5) * density;
}

float lightIntensity(float lightLocation, float2 direction, float2 position, float frequency, float clampValue, float density, float phaseShift)
{
    float location = lightLocation * frequency + dot(position, direction);
    return smoothstep(clampValue, 1, sin(location + phaseShift) * 0.5 + 0.5) * density;
}
