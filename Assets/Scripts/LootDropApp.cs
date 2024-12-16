using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Xml.Linq;

[System.Serializable]
public class LootItem
{
    public string ItemName;
    public string Rarity;
    public int Weight;
    public GameObject LootItemObject;
    

    public LootItem(string name, string rarity, int weight, GameObject gameObject)
    {
        ItemName = name;
        Rarity = rarity;
        Weight = weight;
        LootItemObject = gameObject;
    }
}

public class LootDropApp : MonoBehaviour
{
    [Header("UI Elements")]
    public TMP_Dropdown AlgorithmDropdown;
    public TMP_Dropdown LootPoolSizeDropdown;
    public Button GenerateButton;
    public Button EmptyItemsButton;
    public TMP_InputField SimulationCountInput; 
    public TMP_Text OutputText;

    [Header("Scene Elements")]
    public Transform SpawnPoint;

    [Header("Loot Pool")]
    private List<LootItem> LootPool;
    private List<GameObject> SpawnedItems;
    private int TotalWeight;
    private readonly Dictionary<string, float> RarityBrackets = new Dictionary<string, float>
    {
        { "Common", 0.6f },    
        { "Uncommon", 0.25f }, 
        { "Rare", 0.1f },      
        { "Legendary", 0.04f },
        { "Mythic", 0.01f }    
    };

    [Header("Loot Item Prefabs")]
    public GameObject CommonItem;
    public GameObject UncommonItem;
    public GameObject RareItem;
    public GameObject LegendaryItem;
    public GameObject MythicItem;

    [Header("Metrics")]
    private Dictionary<string, int> DropCounts; // Records number of times each item drops
    private System.Diagnostics.Stopwatch Stopwatch;

    private void Awake()
    {
        LootPool = new List<LootItem>();
        SpawnedItems = new List<GameObject>();
    }
    private void Start()
    {
        // Initialize metrics dictionary
        DropCounts = new Dictionary<string, int>();
        Stopwatch = new System.Diagnostics.Stopwatch();

        // Populate dropdown options
        AlgorithmDropdown.options = new List<TMP_Dropdown.OptionData>
        {
            new TMP_Dropdown.OptionData("Weighted Random"),
            new TMP_Dropdown.OptionData("Loot Tiers")
        };
        
    }

    public void InitLootPool(int poolSize)
    {
        LootPool.Clear();

        // Add one Legendary and Mythic Item to guaruntee they're in the Pool
        LootPool.Add(new LootItem($"Legendary Item 1", "Legendary", GetWeightForRarity("Legendary"), GetAssignLootGameObject("Legendary")));
        LootPool.Add(new LootItem($"Mythic Item 1", "Mythic", GetWeightForRarity("Mythic"), GetAssignLootGameObject("Mythic")));

        int remainingSize = poolSize - LootPool.Count;

        // Calculate how many items of each rarity
        foreach (var rarity in RarityBrackets)
        {
            int count = Mathf.RoundToInt(remainingSize * rarity.Value);

            // Add items to the pool
            for (int i = 0; i < count; i++)
            {                
                LootPool.Add(new LootItem($"{rarity.Key} Item {i + 1}", rarity.Key, GetWeightForRarity(rarity.Key), GetAssignLootGameObject(rarity.Key)));
            }
        }

        // Ensure the pool size matches exactly by adjusting common items
        while (LootPool.Count < poolSize)
        {
            LootPool.Add(new LootItem($"Common Item {LootPool.Count + 1}", "Common", GetWeightForRarity("Common"), GetAssignLootGameObject("Common")));
        }

        

        Debug.Log($"Initialized loot pool with {LootPool.Count} items.");
    }


    // Helper method to define weights for each rarity
    private int GetWeightForRarity(string rarity)
    {
        switch (rarity)
        {
            case "Common": return 60;
            case "Uncommon": return 25;
            case "Rare": return 10;
            case "Legendary": return 4;
            case "Mythic": return 1;
            default: return 0;
        }
    }

    // Helprer to assign a LootItem with a GameObject
    private GameObject GetAssignLootGameObject(string rarity)
    {
        switch (rarity)
        {
            case "Common": return CommonItem;
            case "Uncommon": return UncommonItem;
            case "Rare": return RareItem;
            case "Legendary": return LegendaryItem;
            case "Mythic": return MythicItem;
            default: return CommonItem;
        }
    }

    public void GenerateDrops()
    {
        string selectedLootPoolSize = LootPoolSizeDropdown.options[LootPoolSizeDropdown.value].text;
        InitLootPool(int.Parse(selectedLootPoolSize));
        EmptyItems();

        if (LootPool.Count == 0)
        {
            OutputText.text = "Error: Loot pool is empty!";
            return;
        }

        // Reset metrics
        DropCounts.Clear();

        // init weighted items list
        foreach (var item in LootPool)
        {
            DropCounts[item.ItemName] = 0;
        }

        // Get simulation count
        string inputString = SimulationCountInput.text;
        int simulationCount;
        if (int.TryParse(inputString, out simulationCount))
        {
            Debug.Log("Parsed number: " + simulationCount);
        }
        else
        {
            Debug.LogError("Invalid number format.");
        }
        if (simulationCount <= 0)
        {
            OutputText.text = "Error: Simulation count must be greater than 0!";
            return;
        }

        // Select algorithm and calculate drops
        string selectedAlgorithm = AlgorithmDropdown.options[AlgorithmDropdown.value].text;
        Stopwatch.Reset();
        Stopwatch.Start();

        for (int i = 0; i < simulationCount; i++)
        {
            LootItem drop = null;
            if (selectedAlgorithm == "Weighted Random")
            {
                drop = GetWeightedRandomLoot();
            }

            else if (selectedAlgorithm == "Loot Tiers")
            {
                Debug.Log("Alg dropdown works");
                drop = GetLootFromTiers(); // You can add tiers in future extensions
            }

            if (drop != null)
            {
                DropCounts[drop.ItemName]++;
            }
        }

        Stopwatch.Stop();

        // Display metrics
        DisplayMetrics(simulationCount, selectedAlgorithm);
    }

    private LootItem GetWeightedRandomLoot()
    {

        
        // Calculate total weight if not already done
        if (TotalWeight == 0)
        {
            foreach (var item in LootPool)
            {
                TotalWeight += item.Weight;
            }
        }

        int randomWeight = Random.Range(0, TotalWeight);
        int cumulativeWeight = 0;

        foreach (var item in LootPool)
        {
            cumulativeWeight += item.Weight;
            if (randomWeight < cumulativeWeight)
            {
                GameObject spawnedObjectInstance = Instantiate(item.LootItemObject, SpawnPoint.transform); 
                SpawnedItems.Add(spawnedObjectInstance);

                Rigidbody2D rb = spawnedObjectInstance.GetComponent<Rigidbody2D>();
                // Apply a random velocity in a horizontal direction
                Vector3 randomVelocity = new Vector3(
                    Random.Range(-2f, 2f), // Random X velocity
                    Random.Range(1f, 3f),  // Small upward Y velocity
                    Random.Range(-2f, 2f)  // Random Z velocity
                );
                rb.velocity = randomVelocity;
                return item;
            }
        }

        return null;
    }


    private LootItem GetLootFromTiers()
    {
        // Step 1: Select Rarity Tier Based on Probabilities
        string selectedRarity = GetRarityFromTiers();

        // Step 2: Filter LootPool to get items matching the selected rarity
        List<LootItem> filteredItems = LootPool.FindAll(item => item.Rarity == selectedRarity);

        // Step 3: Randomly pick an item from the filtered list
        if (filteredItems.Count > 0)
        {
            int randomIndex = Random.Range(0, filteredItems.Count);

            // Spawn the item in the scene
            LootItem selectedItem = filteredItems[randomIndex];
            GameObject spawnedObject = Instantiate(selectedItem.LootItemObject, SpawnPoint.transform);
            SpawnedItems.Add(spawnedObject);

            Rigidbody2D rb = spawnedObject.GetComponent<Rigidbody2D>();
            Vector3 randomVelocity = new Vector3(
                Random.Range(-2f, 2f),  // Random X velocity
                Random.Range(1f, 3f),   // Small upward Y velocity
                Random.Range(-2f, 2f)   // Random Z velocity
            );
            rb.velocity = randomVelocity;

            return selectedItem;
        }

        Debug.LogWarning("No items available for the selected tier.");
        return null;
    }

    // Helper Method: Select Rarity Tier Based on Probabilities
    private string GetRarityFromTiers()
    {
        // Convert rarity probabilities into cumulative percentages
        List<string> rarities = new List<string>(RarityBrackets.Keys);
        List<float> cumulativeProbabilities = new List<float>();

        float cumulative = 0f;
        foreach (var rarity in rarities)
        {
            cumulative += RarityBrackets[rarity];
            cumulativeProbabilities.Add(cumulative);
        }

        // Generate a random float [0, 1) to determine the rarity
        float randomValue = Random.value;

        // Compare against cumulative probabilities
        for (int i = 0; i < cumulativeProbabilities.Count; i++)
        {
            if (randomValue <= cumulativeProbabilities[i])
            {
                return rarities[i];
            }
        }

        // Fallback to Common
        return "Common";
    }


    private void DisplayMetrics(int simulationCount, string algorithm)
    {
        string metrics = $"Algorithm: {algorithm}\n";
        metrics += $"Total Simulations: {simulationCount}\n";
        metrics += $"Execution Time: {Stopwatch.ElapsedMilliseconds} ms\n";
        metrics += "Drop Frequencies:\n";

        foreach (var item in DropCounts)
        {
            float percentage = (float)item.Value / simulationCount * 100;
            metrics += $"- {item.Key}: {item.Value} drops ({percentage:F2}%)\n";
        }

        OutputText.text = metrics;
    }

    public void EmptyItems()
    {
        if(SpawnedItems.Count > 0 && SpawnedItems != null)
        {
            foreach (GameObject item in SpawnedItems)
            {
                Destroy(item);
            }
        }
        SpawnedItems.Clear();
    }
}
