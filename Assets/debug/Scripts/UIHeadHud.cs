using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIHeadHud : MonoBehaviour
{

	public Transform Traget;
	public RectTransform Self;
	private Canvas cav;

	private void Awake()
	{
		cav = GameObject.Find("Canvas").GetComponent<Canvas>();
	}



	// Update is called once per frame
	void Update()
	{
		if (Traget != null)
		{
			Vector2 screenPos = Camera.main.WorldToScreenPoint(Traget.position);
			Vector3 globalMousePos;
			if (RectTransformUtility.ScreenPointToWorldPointInRectangle (Self, screenPos, /*null*/cav.worldCamera, out globalMousePos)) {
				//Debug.LogError ("hit");
				Self.position = globalMousePos;
			} else {
				//Debug.LogError ("not hit");
			}
				
		}
			
	}



}
